/* Assume Role Policy for Backups */
data "aws_iam_policy_document" "foundry-aws-backup-service-assume-role-policy-doc" {
  statement {
    sid     = "AssumeServiceRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

/* The policies that allow the backup service to take backups and restores */
data "aws_iam_policy" "aws-backup-service-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

data "aws_iam_policy" "aws-restore-service-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

data "aws_caller_identity" "current_account" {}

/* Needed to allow the backup service to restore from a snapshot to an EC2 instance
 See https://stackoverflow.com/questions/61802628/aws-backup-missing-permission-iampassrole */
data "aws_iam_policy_document" "foundry-pass-role-policy-doc" {
  statement {
    sid       = "foundryPassRole"
    actions   = ["iam:PassRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::${data.aws_caller_identity.current_account.account_id}:role/*"]
  }
}

/* Roles for taking AWS Backups */
resource "aws_iam_role" "foundry-aws-backup-service-role" {
  name               = "foundryAWSBackupServiceRole"
  description        = "Allows the AWS Backup Service to take scheduled backups"
  assume_role_policy = data.aws_iam_policy_document.foundry-aws-backup-service-assume-role-policy-doc.json

  tags = {
    Project = "foundry"
    Role    = "iam"
  }
}

resource "aws_iam_role_policy" "foundry-backup-service-aws-backup-role-policy" {
  policy = data.aws_iam_policy.aws-backup-service-policy.policy
  role   = aws_iam_role.foundry-aws-backup-service-role.name
}

resource "aws_iam_role_policy" "foundry-restore-service-aws-backup-role-policy" {
  policy = data.aws_iam_policy.aws-restore-service-policy.policy
  role   = aws_iam_role.foundry-aws-backup-service-role.name
}

resource "aws_iam_role_policy" "foundry-backup-service-pass-role-policy" {
  policy = data.aws_iam_policy_document.foundry-pass-role-policy-doc.json
  role   = aws_iam_role.foundry-aws-backup-service-role.name
}

locals {
  backups = {
    schedule  = "cron(0 0 ? * THU *)"
    retention = 60 // days
  }
}

resource "aws_backup_vault" "foundry-backup-vault" {
  name = "foundry-backup-vault"
  tags = {
    application = "FoundryVTT"
    Role    = "backup-vault"
  }
}

resource "aws_backup_plan" "foundry-backup-plan" {
  name = "foundry-backup-plan"

  rule {
    rule_name         = "weekly-${local.backups.retention}-day-retention"
    target_vault_name = aws_backup_vault.foundry-backup-vault.name
    schedule          = local.backups.schedule
    start_window      = 60
    completion_window = 300

    lifecycle {
      delete_after = local.backups.retention
    }

    recovery_point_tags = {
      application = "FoundryVTT"
      Creator = "aws-backups"
    }
  }

  tags = {
    application = "FoundryVTT"
    Role    = "backup"
  }
}

resource "aws_backup_selection" "foundry-server-backup-selection" {
  iam_role_arn = aws_iam_role.foundry-aws-backup-service-role.arn
  name         = "foundry-server-resources"
  plan_id      = aws_backup_plan.foundry-backup-plan.id

  //root_block_device
  resources = [
    aws_instance.foundry_server.arn,
    # aws_instance.foundry_server.root_block_device.arn,
  ]
}

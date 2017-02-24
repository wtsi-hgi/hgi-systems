terragrunt = {
  # Configure Terragrunt to use DynamoDB for locking
  lock {
    backend = "dynamodb"
    config {
      state_file_id = "${path_relative_to_include()}/${get_env("ENV", "staging")}"
    }
  }

  # Configure Terragrunt to automatically store tfstate files in an S3 bucket
  remote_state {
    backend = "s3"
    config {
      encrypt = "true"
      bucket = "${get_env("TERRAFORM_S3_BUCKET")}"
      endpoint = "${get_env("TERRAFORM_S3_ENDPOINT")}"
      access_key = "${get_env("TERRAFORM_S3_ACCESS_KEY")}"
      secret_key = "${get_env("TERRAFORM_S3_SECRET_KEY")}"
      key = "${path_relative_to_include()}/${get_env("ENV", "staging")}.tfstate"
    }
  }
}
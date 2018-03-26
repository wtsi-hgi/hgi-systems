terragrunt = {
  # Configure Terragrunt to use DynamoDB for locking
  lock {
    backend = "dynamodb"
    config {
      state_file_id = "${path_relative_to_include()}/${get_env("ENV", "staging")}"
      aws_region = "eu-west-1"
      table_name = "terragrunt_locks"
    }
  }
}
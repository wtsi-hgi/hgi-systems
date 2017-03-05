terraform {
  backend "minio" {
      bucket_name = "terraform-remote-state"
      object_name = "delta-hgi/staging.tfstate"
      endpoint = "cog.sanger.ac.uk"
  }
}
		
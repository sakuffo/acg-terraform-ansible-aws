# First configure keys. This is overwrite for default. Investigate if there is a different way to do this
aws configure

# Then create s3 bucket 
aws s3 mb s3://saa-terraform-state-bucket --region us-east-1
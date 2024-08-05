deploy-site:
	aws s3 sync ./resume-site s3://droberts-serverless-cloud-resume-challenge --profile cloud-resume-site
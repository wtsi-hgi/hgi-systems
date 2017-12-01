#!/usr/bin/env python3

import os
from urllib.parse import urlparse

from gitlab import Gitlab

pipeline_id = int(os.environ["CI_PIPELINE_ID"])
project_id = os.environ["CI_PROJECT_ID"]
_parsed_project_url = urlparse(os.environ["CI_PROJECT_URL"])
ci_url = "%s://%s" % (_parsed_project_url.scheme, _parsed_project_url.netloc)
gitlab_token = os.environ["GITLAB_TOKEN"]

gitlab_client = Gitlab(ci_url, gitlab_token, api_version=4)
gitlab_client.auth()

project = gitlab_client.projects.get(project_id)
latest_pipelines = project.pipelines.list(status=["running", "pending"], order_by="id", sort="desc", per_page=1)

if len(latest_pipelines) == 0:
    print("No running pipelines (has a single job been retried?) - continuing")
    exit(0)
else:
    latest_pipeline = latest_pipelines[0]

assert pipeline_id <= latest_pipeline.id

if pipeline_id < latest_pipeline.id:
    print("Running pipeline (%s) is not the latest (%s) - cancelling self" % (pipeline_id, latest_pipeline.id))
    pipeline = project.pipelines.get(pipeline_id, lazy=True)
    pipeline.cancel()
else:
    print("Running pipeline (%s) is the latest - continuing" % (pipeline_id, ))

exit(0)

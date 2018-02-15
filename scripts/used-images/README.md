## About
This is a tool to investigate which OpenStack images within an S3 bucket are used, or have been used in the past, in our
setup.

## Prerequisites
- Python 3.6+
- jq

## Usage
### Local
#### Setup
```bash
pip install -r investigator/requirements.txt
```

#### Run
```bash
S3_SECRET_KEY=xxx S3_ACCESS_KEY=xxx S3_HOST=cog.sanger.ac.uk ./investigate.py
```

### Docker
```bash
docker build -t mercury/used-image-investigator -f investigator/Dockerfile investigator
```

#### Run
```bash
S3_SECRET_KEY=xxx S3_ACCESS_KEY=xxx S3_HOST=cog.sanger.ac.uk docker run \
    -e S3_SECRET_KEY -e S3_ACCESS_KEY -e S3_HOST \
    -v $PWD/investigate.py:/investigate.py \
    mercury/used-image-investigator /investigate.py
```

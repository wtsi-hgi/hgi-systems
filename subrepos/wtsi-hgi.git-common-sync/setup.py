from setuptools import setup, find_packages

try:
    from pypandoc import convert
    def read_markdown(file: str) -> str:
        return convert(file, "rst")
except ImportError:
    def read_markdown(file: str) -> str:
        return open(file, "r").read()

setup(
    name="gitcommonsync",
    version="1.2.0",
    packages=find_packages(exclude=["tests"]),
    install_requires=open("requirements.txt", "r").readlines(),
    url="https://github.com/wtsi-hgi/git-common-sync",
    license="MIT",
    description="A tool to synchronise common files between Git repositories",
    long_description=read_markdown("README.md")
)

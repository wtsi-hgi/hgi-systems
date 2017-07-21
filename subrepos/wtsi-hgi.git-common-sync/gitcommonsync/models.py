from abc import ABCMeta
from typing import Dict

from gitcommonsync.repository import GitCheckout


class Synchronisation(metaclass=ABCMeta):
    """
    Synchronisation configuration.
    """


class SubrepoSynchronisation(Synchronisation):
    """
    Subrepo synchronisation configuration.
    """
    @property
    def destination(self) -> str:
        return self.checkout.directory

    def __init__(self, checkout: GitCheckout =None, overwrite: bool=False):
        self.checkout = checkout
        self.overwrite = overwrite


class FileSynchronisation(Synchronisation):
    """
    File synchronisation configuration.
    """
    def __init__(self, source: str, destination: str, overwrite: bool=False):
        self.source = source
        self.destination = destination
        self.overwrite = overwrite


class TemplateSynchronisation(FileSynchronisation):
    """
    Template synchronisation configuration.
    """
    def __init__(self, source: str, destination: str, variables: Dict[str, str], overwrite: bool=False):
        super().__init__(source, destination, overwrite=overwrite)
        self.variables = variables

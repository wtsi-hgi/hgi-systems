from collections import defaultdict
from typing import List, Dict, Type, DefaultDict

from gitcommonsync.repository import GitRepository
from gitcommonsync.models import FileSynchronisation, SubrepoSynchronisation, TemplateSynchronisation
from gitcommonsync.synchronisers import FileSynchroniser, TemplateSynchroniser, SubrepoSynchroniser, Synchronisable, \
    Synchroniser

synchronisable_to_synchroniser = {
    SubrepoSynchronisation: SubrepoSynchroniser,
    FileSynchronisation: FileSynchroniser,
    TemplateSynchronisation: TemplateSynchroniser
}


def synchronise(repository: GitRepository, synchronisables: List[Synchronisable], dry_run: bool=False) \
        -> DefaultDict[Type[Synchronisable], List[Synchronisable]]:
    """
    Performs the given synchronisations on the given repository and (by default) pushes back to the source repository.
    :param repository: the git repository
    :param synchronisables: the synchronisations to apply
    :param dry_run: does not push changes back if set to True
    :return: the synchronisations applied, indexed by synchronisation type
    """
    jobs: Dict[Type[Synchroniser], List[Synchronisable]] = defaultdict(list)
    synchronised: Dict[Type[Synchronisable], List[Synchronisable]] = defaultdict(list)

    for synchronisation in synchronisables:
        assert type(synchronisation) in synchronisable_to_synchroniser
        synchroniser_type = synchronisable_to_synchroniser[type(synchronisation)]
        jobs[synchroniser_type].append(synchronisation)

    if len(synchronisables) > 0:
        try:
            repository.checkout()
            for synchroniser_type, synchronisables in jobs.items():
                assert len(synchronisables) > 0
                synchroniser = synchroniser_type(repository)
                synchronisable_type = type(synchronisables[0])
                synchronised[synchronisable_type] = synchroniser.synchronise(synchronisables, dry_run=dry_run)
        finally:
            repository.tear_down()

    return synchronised

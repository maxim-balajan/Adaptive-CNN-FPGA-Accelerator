

def safe_read(config:dict, key: str, default=None):
    try:
        return config[key]
    except KeyError:
        if default is not None:
            return default
        else:
            raise NameError(f'Error: Could not find necessary key "{key}" in Config! Abort...')  


def get_nth_key(dictionary, n=0):
    if n < 0:
        n += len(dictionary)
    for i, key in enumerate(dictionary.keys()):
        if i == n:
            return key
    raise IndexError("dictionary index out of range") 

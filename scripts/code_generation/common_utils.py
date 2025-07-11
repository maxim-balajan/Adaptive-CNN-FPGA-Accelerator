

def safe_read(config:dict, key: str, default=None):
    try:
        return config[key]
    except KeyError:
        if default is not None:
            return default
        else:
            raise NameError(f'Error: Could not find necessary key "{key}" in Config! Abort...')  

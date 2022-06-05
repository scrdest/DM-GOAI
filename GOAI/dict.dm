/dict
	var/list/contents = list()


/dict/New(var/list/init_memories = null)
	contents = isnull(init_memories) ? list() : init_memories.Copy()
	return


/dict/proc/Copy()
	var/dict/newdict = new(contents.Copy())
	return newdict


/dict/proc/Items()
	return contents.Copy()


/dict/proc/Get(var/key, var/default = null)
	if (key in contents)
		return contents[key]

	return default


/dict/proc/Set(var/key, var/val)
	contents[key] = val
	return src


/dict/proc/operator[](idx)
	return Get(idx)


/dict/proc/operator[]=(idx, B)
	return Set(idx, B)

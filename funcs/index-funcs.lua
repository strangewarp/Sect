
return {
	
	-- Build a table whose keys are a given chain of indices, within a given context
	-- Example data structure for function call:
	-- bool = buildTable(tab.stuff, {1, 5, "branch", 2}, "foo")
	buildTable = function(context, indices, item)

		if #indices > 1 then
			local index = table.remove(indices, 1)
			context[index] = context[index] or {}
			buildTable(context[index], indices, item)
		else
			if item ~= nil then
				context[indices[1]] = ((type(item) == 'table') and deepCopy(item)) or item
			end
		end

	end,

	-- Get the contents of a table-index whose keys are a given chain of indices,
	-- or return nil if it doesn't exist.
	-- Example data structure for function call:
	-- bool = getIndex(tab.stuff, {1, 5, "branch", 2})
	getIndex = function(context, indices)

		local path = deepCopy(context)

		for _, v in ipairs(indices) do
			if path[v] == nil then
				return nil
			end
			path = path[v]
		end

		return path

	end,

	-- Run a series of iterators on a table structure,
	-- and return all elements as a flat table,
	-- optionally returning tables containing the chains of keys that led to each item.
	-- Example data structure for function call:
	-- tab = getContents(tab.stuff, {1, "thing", pairs, ipairs, 2}, true)
	getContents = function(context, keychain, gethist, history, out)

		out = out or {}

		-- If this portion of the context-chain doesn't exist, then return the out-table
		if context == nil then
			return out
		end

		-- Make a copy of the keychain, to prevent sticky-reference errors
		local modkeys = deepCopy(keychain)

		-- If history is to be returned, then start tracking history
		if gethist then
			history = history or {}
		end

		-- If any meta-keys remain...
		if #modkeys > 0 then

			-- Get the bottommost key or iterator
			local token = table.remove(modkeys, 1)
			local tokentype = type(token)

			-- If the token is a function, assume it's an iterator, and treat it as such
			if tokentype == 'function' then

				-- Iterate through the context-tab, using the given iterator.
				for k, v in token(context) do

					-- If tracking history, add the current iterator-key to a new history-table
					local histnew = false
					if gethist then
						histnew = deepCopy(history)
						table.insert(histnew, k)
					end

					-- Run a new getContents command on each sub-value.
					out = getContents(context[k], modkeys, gethist, histnew, out)

				end

			-- If the token is a table, treat each item as a new index
			elseif tokentype == 'table' then

				-- For each table item, if a table with that name exists in context...
				for _, v in pairs(token) do
					if context[v] ~= nil then

						-- If tracking history, add the current iterator-key to a new history-table
						local histnew = false
						if gethist then
							histnew = deepCopy(history)
							table.insert(histnew, v)
						end

						-- Run a new getContents command on each index-value.
						out = getContents(context[v], modkeys, gethist, histnew, out)

					end
				end

			else -- Else, assume the token is an index, and treat is as such

				-- If tracking history, add the current token to a new history-table
				local histnew = false
				if gethist then
					histnew = deepCopy(history)
					table.insert(histnew, token)
				end

				-- Run a new getContents command on the table signified by the token.
				out = getContents(context[token], modkeys, gethist, histnew, out)

			end

		else -- If no meta-keys remain...

			-- If the context isn't an empty table or nil...
			local contexttype = type(context)
			if not (
				((contexttype == 'table') and (#context == 0))
				or ((contexttype ~= 'table') and (context == nil))
			)
			then

				-- Get a copy of the top context-item we've arrived at
				local item = ((type(context) == 'table') and deepCopy(context)) or context

				-- If we were tracking key-history, put the item and history into a table
				if gethist then
					item = {history, item}
				end

				-- Put the item (and the history, if we grabbed it) into the out-table.
				table.insert(out, item)

			end

		end

		return out

	end,

	-- Unset a given note in a given sequence, and then unset all empty tables underneath it
	seqUnsetCascade = function(s, kind, n, cmdkey)

		local tick = n[2] + 1

		if D.seq[s].tick[tick] ~= nil then
			if D.seq[s].tick[tick][kind] ~= nil then
				if cmdkey and (kind == 'cmd') then -- Cascade-unset a value in the cmd table
					if D.seq[s].tick[tick][kind][cmdkey] ~= nil then
						table.remove(D.seq[s].tick[tick][kind], cmdkey)
					end
				elseif kind == 'note' then -- Cascade-unset a value in the note table
					if D.seq[s].tick[tick][kind][n[4]] ~= nil then
						if D.seq[s].tick[tick][kind][n[4]][n[5]] ~= nil then
							D.seq[s].tick[tick][kind][n[4]][n[5]] = nil
						end
					end
					if next(D.seq[s].tick[tick][kind][n[4]]) then return nil end
					D.seq[s].tick[tick][kind][n[4]] = nil
				end
				if next(D.seq[s].tick[tick][kind]) then return nil end
				D.seq[s].tick[tick][kind] = nil
			end
			if next(D.seq[s].tick[tick]) then return nil end
			D.seq[s].tick[tick] = nil
		end

	end,

	-- Unset a given note in a given copy-tab, and then unset all empty tables underneath it
	copyUnsetCascade = function(kind, n)

		local tick = n[2] + 1

		if D[kind][tick] ~= nil then
			if D[kind][tick][n[4]] ~= nil then
				if D[kind][tick][n[4]][n[5]] ~= nil then
					D[kind][tick][n[4]][n[5]] = nil
				end
				for _, _ in pairs(D[kind][tick][n[4]]) do return nil end
				D[kind][tick][n[4]] = nil
			end
			for _, _ in pairs(D[kind][tick]) do return nil end
			D[kind][tick] = nil
		end

	end,

}


return {

	-- Return true on a note overlap, or false otherwise
	checkNoteOverlap = function(n1, n2, durbool)

		durbool = durbool or false

		return (
			( -- Note is removal-abstraction, and overlaps both pitch and tick
				noteRemoveCompare(n1, n2)
			)
			or ( -- Notes are note-type, and overlap in both pitch and tick
				(n1.note[1] == 'note')
				and (n2.note[1] == 'note')
				and (n1.note[5] == n2.note[5])
				and (
					(
						durbool -- Check for duration overlap
						and (
							rangeCheck(n1.note[5], n2.note[5], n2.note[5] + n2.note[3])
							or rangeCheck(n2.note[5], n1.note[5], n1.note[5] + n1.note[3])
						)
					)
					-- Check for initial-tick overlap only
					or (n1.note[5] == n2.note[5])
				)
			)
			or ( -- Notes are not note-type, and overlap in both type and tick
				(n1.note[1] ~= 'note')
				and (n2.note[1] ~= 'note')
				and (n1.note[1] == n2.note[1])
				and (n1.note[4] == n2.note[4])
			)
		)

	end,

	-- Check whether a note-remove command matches a note, across note values
	noteRemoveCompare = function(n1, n2, iter)

		return (
			((iter == nil) and noteRemoveCompare(n2, n1, false))
			or (
				(n1.note[1] == 'remove')
				and (
					(
						((n2.note[1] == 'note') and (n1.note[2] == n2.note[5]))
						or ((n2.note[1] ~= 'note') and (n1.note[2] == n2.note[4]))
					)
					and (n1.tick == n2.tick)
				)
			)
		)

	end,

	-- Set a group of note-subtables to false, which represents removal
	notesToRemove = function(notes)

		for k, v in pairs(notes) do
			if v.note[1] == 'note' then
				notes[k].note = {'remove', v.note[5]}
			elseif v.note[1] ~= 'remove' then
				notes[k].note = {'remove', v.note[4]}
			end
		end

		return notes

	end,

}
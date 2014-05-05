
return {

	-- Return true on a note overlap, or false otherwise
	checkNoteOverlap = function(n1, n2, durbool)

		durbool = durbool or false

		return (
			( -- Notes are note-type, and overlap in both pitch and tick
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

}
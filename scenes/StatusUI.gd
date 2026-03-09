extends Object
class_name StatusUI

# Returns a short display string for a status dict, e.g. "💀Poison:3 🔥Burn:2"
static func format_statuses(statuses: Dictionary) -> String:
	var parts := []
	var icons := {
		"poison": "💀",
		"burn": "🔥",
		"weak": "😵",
		"vulnerable": "💢",
		"frail": "🩹",
		"strength": "💪",
		"dexterity": "🤸",
		"artifact": "🏺",
		"thorns": "🌵"
	}
	for id in statuses:
		var stacks: int = statuses[id]
		if stacks > 0:
			var icon: String = icons.get(id, "❓")
			parts.append("%s%s:%d" % [icon, id.capitalize(), stacks])
	return " ".join(parts)

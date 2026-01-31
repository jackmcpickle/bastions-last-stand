class_name ChapterData extends Resource

@export var id: String  # "chapter_1"
@export var display_name: String  # "The First Stand"
@export var description: String
@export var levels: Array[LevelData] = []
@export var unlock_requirement: String  # Previous chapter ID or ""

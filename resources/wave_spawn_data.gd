class_name WaveSpawnData
extends Resource

## Individual spawn group within a wave

@export var enemy_id: String  # References EnemyData.id
@export var count: int  # Number of this enemy type
@export var spawn_point_index: int = -1  # -1 = random/alternating, 0+ = specific spawn
@export var delay_ms: int = 0  # Delay before this group starts spawning

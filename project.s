.data
# game setting
monster_base: .word 0 # base id of monsters
monster_num: .word 0 # the number of monsters
remaining_monster_num: .word 0 # remaining number of monsters
input_monster_num: .asciiz "Enter the number of monsters (in the range [1,5]): "
game_win_text: .asciiz "You Win! Enjoy the game brought by COMP2611!"
game_lose_text: .asciiz "You Loss... Try harder in the next trial!"
background_sound_on: .word 0 # 1 if background sound is on, otherwise 0
loc_separation: .word 150 # the minimum horizontal or vertical separation distance (in pixels) between the bomberman object's current location and another object's initial location
# movement
input_key: .word 0 # input key from the player
move_iteration: .word 0 # remaining number of game iterations for last bomberman movement
initial_move_iteration: .word 10 # default number of game iterations for a bomberman movement
move_key: .word 0 # last processed key for a bomberman movement
buffered_move_key: .word 0 # latest buffered movement input during an in-progress bomberman movement
# bomberman properties
bomberman_id: .word 0 # id of bomberman object is set to 0
bomberman_locs: .word -1:2 # initialized location of bomberman object
bomberman_speed: .word 3
# bomb
bomb_id: .word 0
bomb_locs: .word -1:2 # initialized location of bomberman object
bomb_timer: .word 80 # explosion timer for a bomb
# size properties
bomberman_size: .word 30 30 # width and height of bomberman object
bomb_size: .word 30 30 # width and height of bomb object
monster_size: .word 30 30 # width and height of monster object
maze_size: .word 780 630 # width and height of the maze
grid_cell_size: .word 30 30 # width and height of a grid cell
grid_row_num: .word 21 # the number of rows in the grid of the maze
grid_col_num: .word 25 # the number of columns in the grid of the maze
maze_destroy: .word -1:8
# maze bit map
maze_bitmap: .byte
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 0 0 0 2 0 0 0 2 0 0 2 2 2 2 0 0 0 0 0 2 2 0 0 1
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 2 1 0 1 0 1
1 0 2 0 2 0 2 0 2 0 0 2 2 0 2 2 0 0 2 2 2 0 0 0 1
1 2 1 0 1 0 1 2 1 0 1 0 1 0 1 0 1 0 1 2 1 2 1 2 1
1 2 2 2 0 0 0 0 0 2 0 0 0 0 2 0 0 2 2 2 0 2 2 2 1
1 2 1 0 1 0 1 0 1 2 1 0 1 0 1 2 1 0 1 0 1 0 1 2 1
1 2 0 0 0 0 0 2 2 0 0 0 0 2 2 2 2 0 0 0 0 0 0 0 1
1 2 1 0 1 2 1 0 1 2 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1
1 2 0 2 2 2 0 0 2 0 0 0 0 0 0 2 0 0 0 2 2 2 2 0 1
1 2 1 2 1 2 1 0 1 0 1 0 1 0 1 0 1 2 1 2 1 0 1 0 1
1 0 0 0 0 2 0 0 0 2 0 0 0 0 0 2 0 0 0 0 0 0 2 0 1
1 2 1 0 1 2 1 0 1 0 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1
1 0 0 0 2 2 0 0 0 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 1
1 0 1 0 1 2 1 2 1 0 1 0 1 1 1 0 1 1 1 0 1 0 1 0 1
1 0 0 2 0 0 0 2 0 0 2 0 0 0 1 0 1 0 0 0 1 0 1 0 1
1 0 1 2 1 0 1 0 1 2 1 0 1 1 1 0 1 1 1 0 1 0 1 0 1
1 2 0 2 0 2 0 0 0 0 2 0 1 0 0 0 1 0 1 0 1 0 1 0 1
1 0 1 2 1 0 1 0 1 0 1 0 1 1 1 0 1 1 1 0 1 0 1 0 1
1 0 0 0 0 2 0 0 0 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
.text
main:
 	jal input_game_params
 	la $t0, monster_num
 	sw $v0, 0($t0)
	la $t0, remaining_monster_num
	sw $v0, 0($t0)
	li $v0, 100 # create the screen
	syscall
	
 	li $a0, 0
	li $a1, 1
	li $v0, 102
	syscall
	la $t0, background_sound_on
	li $t1, 1
	sw $t1, 0($t0)
	
 	# Initialize the game
 	jal init_game
game_loop:
 	jal get_time
	add $s6, $v0, $zero # $s6: starting time of the game
 	jal get_keyboard_input
 	
game_continue:
 	jal check_monster_collisions
 	li $a0, 0
 	bne $v0, $zero, end_game # collisions with any monsters
 	jal check_place_bomb
	jal check_explosion_collision
 	j game_move_monster

game_move_monster:
 	li $v0, 108 # move all monsters for one game iteration
 	syscall
 	
game_move_user:
 	jal process_move_input
 	j game_refresh
 	
game_refresh: # refresh screen
 	li $v0, 101
 	syscall
 	add $a0, $s6, $zero
 	addi $a1, $zero, 30 # iteration gap: 30 milliseconds
 	jal have_a_nap
 	j game_loop
 	
#--------------------------------------------------------------------
# input_game_params
#--------------------------------------------------------------------
input_game_params:
 	la $a0, input_monster_num
 	li $v0, 4
 	syscall
 	li $v0, 5
 	syscall
 	addi $t0, $v0, 0
 	addi $v0, $t0, 0
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: init_game
# Initialize a new game:
# 1. end any last movement of the bomberman object
# 2. create the bomberman object: located at the point
# 3. create monster_num monster objects;
# their locations are random on the paths of the game maze.
#--------------------------------------------------------------------
init_game:
 	addi $sp, $sp, -12
 	sw $ra, 8($sp)
 	sw $s0, 4($sp)
 	sw $s1, 0($sp)
 	
 	la $t0, move_iteration
 	sw $zero, 0($t0) # reset any last movement of bomberman
 	la $t0, buffered_move_key
 	sw $zero, 0($t0) # reset latest buffered movement input of bomberman
 	
ig_start:
 	# create the bomberman object
 	li $v0, 103
 	la $t0, bomberman_id
 	lw $a0, 0($t0) # the id of bomberman object
 	li $a1, 150 # initial place 150
 	li $a2, 150
 	li $a3, 1
 	la $t0, bomberman_locs
 	sw $a1, 0($t0)
 	sw $a2, 4($t0)
 	syscall
 	
 	# create bombs
 	li $v0, 103
 	la $t0, bomb_id
 	lw $a0, 0($t0) # the id of bomb object
 	li $a1, 1000 # out of screen (hidden)
 	li $a2, 1000
 	li $a3, 0
 	la $t0, bomb_locs
 	sw $a1, 0($t0)
 	sw $s2, 4($t0)
 	syscall
 	
 	# create the specified number of monsters
 	la $t0, monster_num
 	lw $a0, 0($t0) # num of monster objects
 	jal create_multi_monsters
 	
ig_exit:
 	li $v0, 101 # refresh the screen
 	syscall
 	lw $ra, 8($sp)
 	lw $s0, 4($sp)
 	lw $s1, 0($sp)
 	addi $sp, $sp, 12
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time: li $v0, 30
 	syscall # this syscall also changes the value of $a1
 	andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: have_a_nap(last_iteration_time, nap_time)
#--------------------------------------------------------------------
have_a_nap:
 	addi $sp, $sp, -8
 	sw $ra, 4($sp)
 	sw $s0, 0($sp)
 	
 	add $s0, $a0, $a1
 	jal get_time
 	sub $a0, $s0, $v0
 	slt $t0, $zero, $a0
 	bne $t0, $zero, han_p
 	li $a0, 1 # sleep for at least 1ms
 	
han_p: li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
 	syscall
 	
 	lw $ra, 4($sp)
 	lw $s0, 0($sp)
 	addi $sp, $sp, 8
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: get_keyboard_input
# If an input is available, save its ASCII value in the array input_key,
# otherwise save the value 0 in input_key.
#--------------------------------------------------------------------
get_keyboard_input:
 	add $t2, $zero, $zero
 	lui $t0, 0xFFFF
 	lw $t1, 0($t0)
 	andi $t1, $t1, 1
 	beq $t1, $zero, gki_exit
 	lw $t2, 4($t0)
 	
gki_exit:
 	la $t0, input_key
 	sw $t2, 0($t0) # save input key
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: process_move_input
# Continue any last in-progress movement repesented by move_key, and
# save any latest movement input key during that process to the
# buffer buffered_move_key.
# If no in-progress movement, perform the action of the new keyboard
# input input_key if it is a valid movement input for the bomberman object,
# otherwise perform the action of any buffered movement input key
# if it is a valid movement input.
# If an input is processed but it cannot actually move the bomberman
# object (e.g. due to a wall), no more movements will be made in later
# iterations for this input.
#--------------------------------------------------------------------
process_move_input:
 	addi $sp, $sp, -4
 	sw $ra, 0($sp)
 	
 	la $t6, move_iteration
	lw $t5, 0($t6) # remaining number of game iterations for last movement
 	bne $t5, $zero, pmi_last_move # last movement is not completed, so process it
 	la $t0, input_key
 	lw $t1, 0($t0) # new input key
 	la $t0, initial_move_iteration
 	lw $t2, 0($t0)
 	addi $t2, $t2, -1 # count this game iteration for any new movement
 	sw $t2, 0($t6) # first assume new input key is valid
 	la $t8, move_key
 	sw $t1, 0($t8) # save new input key in case it is a movement key
 	j pmi_check_buffer
 	
pmi_last_move:
	la $t0, input_key
 	lw $t7, 0($t0) # new input key
 	li $t0, 119 # corresponds to key 'w'
 	beq $t7, $t0, pmi_buffer
 	li $t0, 115 # corresponds to key 's'
 	beq $t7, $t0, pmi_buffer
 	li $t0, 97 # corresponds to key 'a'
 	beq $t7, $t0, pmi_buffer
 	li $t0, 100 # corresponds to key 'd'
 	beq $t7, $t0, pmi_buffer
 	j pmi_start_move
 	
pmi_buffer:
 	la $t0, buffered_move_key
	sw $t7, 0($t0) # buffer latest movement input of bomberman during the in-progress movement
 
pmi_start_move:
 	addi $t5, $t5, -1 # process last movement for one more game iteration
 	sw $t5, 0($t6)
 	la $t0, move_key
 	lw $t1, 0($t0) # last movement key
 	li $a0, 0 # no needs to check again whether this movement can actually move the object
 	j pmi_check
 
pmi_check_buffer:
 	li $a0, 1 # check whether this movement can actually move the bomberman object
 	la $t0, buffered_move_key
 	lw $t9, 0($t0) # check whether buffered movement input is valid
 	sw $zero, 0($t0) # reset buffer
 	li $t0, 119 # corresponds to key 'w'
 	beq $t1, $t0, pmi_move_up
 	li $t0, 115 # corresponds to key 's'
 	beq $t1, $t0, pmi_move_down
 	li $t0, 97 # corresponds to key 'a'
 	beq $t1, $t0, pmi_move_left
 	li $t0, 100 # corresponds to key 'd'
 	beq $t1, $t0, pmi_move_right
 	sw $t9, 0($t8) # save buffered input key in case it is a movement key
 	addi $t1, $t9, 0
 
pmi_check:
 	li $t0, 119 # corresponds to key 'w'
	beq $t1, $t0, pmi_move_up
 	li $t0, 115 # corresponds to key 's'
 	beq $t1, $t0, pmi_move_down
 	li $t0, 97 # corresponds to key 'a'
 	beq $t1, $t0, pmi_move_left
 	li $t0, 100 # corresponds to key 'd'
 	beq $t1, $t0, pmi_move_right
 	sw $zero, 0($t6) # above assumption of new input key or buffered key being valid is wrong
 	j pmi_exit
 	
pmi_move_up:
 	jal move_bomberman_up
 	j pmi_after_move
 	
pmi_move_down:
 	jal move_bomberman_down
 	j pmi_after_move
 	
pmi_move_left:
 	jal move_bomberman_left
	j pmi_after_move
	
pmi_move_right:
 	jal move_bomberman_right
 	
pmi_after_move:
 	bne $v0, $zero, pmi_exit # actual movement has been made
 	la $t6, move_iteration
 	sw $zero, 0($t6) # current movement is blocked by a wall, so no more movements in later iterations for the move_key
 	j pmi_exit
 	
pmi_exit:
 	lw $ra, 0($sp)
 	addi $sp, $sp, 4
 	jr $ra
#--------------------------------------------------------------------
# procedure: move_bomberman_up()
# Move the bomberman object upward by one step which is its speed.
# Move the object only when the object will not overlap with a wall cell afterward.
# $v0=1 if a movement has been made, otherwise $v0=0.
#--------------------------------------------------------------------
move_bomberman_up:
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s2, 12($sp)
 	sw $s3, 16($sp)
 	sw $s4, 20($sp)
 	
 	la $t0, bomberman_size
 	lw $s3, 0($t0) # bomberman width
 	lw $s4, 4($t0) # bomberman height
 	la $t0, maze_size
 	lw $t2, 4($t0) # maze height
 	
 	la $t0, bomberman_speed
 	lw $t3, 0($t0) # bomberman speed
 	la $s2, bomberman_locs
 	lw $s0, 0($s2) # x_loc
 	lw $s1, 4($s2) # y_loc
 	sub $s1, $s1, $t3 # new y_loc
 	
 	add $t9, $s1, $s4
 	addi $t9, $t9, -1 # y-coordinate of bomberman's bottom corners
 	slt $t4, $t9, $zero # y-coordinate of upper-border is 0
	beq $t4, $zero, mbu_check_path
 	sub $s1, $t2, $s4
 	j mbu_save_yloc
 	
mbu_check_path:
 	# check whether bomberman's top-left corner is in a wall
 	addi $a0, $s0, 0
 	addi $a1, $s1, 0
 	jal get_bitmap_cell
 	slt $v0, $zero, $v0
 	bne $v0, $zero, mbu_no_move
 	
mbu_save_yloc: sw $s1, 4($s2) # save new y_loc
 	la $t0, bomberman_id
 	lw $a0, 0($t0)
 	addi $a1, $s0, 0
 	addi $a2, $s1, 0
 	li $a3, 1 # object type
 	li $v0, 104
 	syscall # set new object location
	li $v0, 1
 	j mbu_exit
 	
mbu_no_move: li $v0, 0

mbu_exit: lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s2, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: move_bomberman_down()
# Move the bomberman object downward by one step which is its speed.
# Move the object only when the object will not overlap with a wall cell afterward.
# $v0=1 if a movement has been made, otherwise $v0=0.
#--------------------------------------------------------------------
move_bomberman_down:
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s2, 12($sp)
 	sw $s3, 16($sp)
 	sw $s4, 20($sp)
 	
 	la $t0, bomberman_size
 	lw $s3, 0($t0) # bomberman width
 	lw $s4, 4($t0) # bomberman height
 	la $t0, maze_size
 	lw $t2, 4($t0) # maze height
 	
 	la $t0, bomberman_speed
 	lw $t3, 0($t0) # bomberman speed
 	la $s2, bomberman_locs
 	lw $s0, 0($s2) # x_loc
 	lw $s1, 4($s2) # y_loc
 	add $s1, $s1, $t3 # new y_loc
 	
 	addi $t2, $t2, -1 # y-coordinate of lower-border is (height - 1)
 	slt $t4, $t2, $s1
 	beq $t4, $zero, mnd_check_path
 	li $s1, 0
 	j mnd_save_yloc
 	
mnd_check_path:
 	# check whether bomberman's bottom-left corner is in a wall
 	addi $a0, $s0, 0
 	add $a1, $s1, $s4
 	addi $a1, $a1, -1 # y-coordinate of bomberman's bottom corners
 	jal get_bitmap_cell
 	slt $v0, $zero, $v0
 	bne $v0, $zero, mnd_no_move
 	
mnd_save_yloc: 
	sw $s1, 4($s2) # save new y_loc
 	la $t0, bomberman_id
 	lw $a0, 0($t0)
 	addi $a1, $s0, 0
 	addi $a2, $s1, 0
 	li $a3, 1 # object type
 	li $v0, 104
 	syscall # set new object location
 	li $v0, 1
 	j mnd_exit
 	
mnd_no_move: 
	li $v0, 0

mnd_exit: 
	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s2, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: move_bomberman_left()
# Move the bomberman object leftward by one step which is its speed.
# Move the object only when the object will not overlap with a wall cell afterward.
# $v0=1 if a movement has been made, otherwise $v0=0.
#--------------------------------------------------------------------
move_bomberman_left:
	# Preserve values $ra, $s0, $s1, $s2, $s3, $s4 with stack
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s2, 12($sp)
 	sw $s3, 16($sp)
 	sw $s4, 20($sp)

 	la $t0, bomberman_size
 	lw $s3, 0($t0) # bomberman width
 	lw $s4, 4($t0) # bomberman height
 	la $t0, maze_size
 	lw $t2, 0($t0) # maze width
 	
 	la $t0, bomberman_speed
 	lw $t3, 0($t0) # bomberman speed
 	la $s2, bomberman_locs
 	lw $s0, 0($s2) # x_loc
 	lw $s1, 4($s2) # y_loc
 	sub $s0, $s0, $t3 # new x_loc

	add $t9, $s0, $s3
	addi $t9, $t9, -1 # x-coordinate of bomerman's top-right corners
	slt $t4, $t9, $zero # x-coordinate of top-left corners
	beq $t4, $zero, mbl_check_path
	sub $s0, $t2, $s3
	j mbl_save_xloc

mbl_check_path: # check whether bomberman's top-left corner is in a wall
 	addi $a0, $s0, 0
 	addi $a1, $s1, 0
 	jal get_bitmap_cell
 	slt $v0, $zero, $v0
 	bne $v0, $zero, mbl_no_move # If it is in a wall, then the bombman can't move
 
mbl_save_xloc: 	# Not wall, then save and set the new x_loc for the bombman object
	sw $s0, 0($s2) # save new x_loc
 	la $t0, bomberman_id
 	lw $a0, 0($t0)
 	addi $a1, $s0, 0
 	addi $a2, $s1, 0
 	li $a3, 1 # object type
 	li $v0, 104
 	syscall # set new object location
 	li $v0, 1
 	j mbl_exit

mbl_no_move: li $v0, 0 # Movement has NOT been made

mbl_exit: # Lastly, pop and restore values in $ra, $s0, $s1, $s2, $s3, $s4 and return
	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s2, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra

#--------------------------------------------------------------------
# procedure: move_bomberman_right()
# Move the bomberman object rightward by one step which is its speed.
# Move the object only when the object will not overlap with a wall cell afterward.
# $v0=1 if a movement has been made, otherwise $v0=0.
#--------------------------------------------------------------------
move_bomberman_right:
	# Preserve values $ra, $s0, $s1, $s2, $s3, $s4 with stack
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s2, 12($sp)
 	sw $s3, 16($sp)
 	sw $s4, 20($sp)

 	la $t0, bomberman_size
 	lw $s3, 0($t0) # bomberman width
 	lw $s4, 4($t0) # bomberman height
 	la $t0, maze_size
 	lw $t2, 0($t0) # maze width
 	
 	la $t0, bomberman_speed
 	lw $t3, 0($t0) # bomberman speed
 	la $s2, bomberman_locs
 	lw $s0, 0($s2) # x_loc
 	lw $s1, 4($s2) # y_loc
 	add $s0, $s0, $t3 # new x_loc
 	
 	addi $t9, $t2, -1
 	slt $t4, $t9, $s0
 	beq $t4, $zero, mbr_check_path
 	li $s0, 0
 	j mbr_save_xloc

mbr_check_path: # Check whether bombman's top-right corner is in a wall
	add $a0, $s0, $s3
	addi $a0, $a0, -1
	addi $a1, $s1, 0
	jal get_bitmap_cell
	slt $v0, $zero, $v0
	bne $v0, $zero, mbr_no_move # If it is in a wall, then the bombman can't move

mbr_save_xloc: 	# Not wall, then save and set the new x_loc for the bombman object
	sw $s0, 0($s2) # save new x_loc
 	la $t0, bomberman_id
 	lw $a0, 0($t0)
 	addi $a1, $s0, 0
 	addi $a2, $s1, 0
 	li $a3, 1 # object type
 	li $v0, 104
 	syscall # set new object location
 	li $v0, 1
 	j mbr_exit

mbr_no_move: li $v0, 0 # Movement has NOT been made

mbr_exit: # Lastly, pop and restore values in $ra, $s0, $s1, $s2, $s3, $s4 and return
	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s2, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra

#--------------------------------------------------------------------
# procedure: get_bitmap_cell(x, y)
# Get the bitmap value for the grid cell containing the given pixel coordinate (x, y).
# The value will be returned in $v0, or -1 will be returned in $v0 if (x, y) is outside the maze.
#--------------------------------------------------------------------
get_bitmap_cell:
 	la $t0, grid_cell_size
 	lw $t1, 0($t0) # cell width
 	lw $t2, 4($t0) # cell height
 	la $t0, grid_col_num
	lw $t3, 0($t0)
 	la $t0, maze_size
 	lw $t7, 0($t0) # maze width
 	lw $t8, 4($t0) # maze height
 	li $v0, -1 # initialize the return value to -1
 	
 	slti $t5, $a0, 0 # check whether x is outside the maze
 	bne $t5, $zero, gbc_exit
 	slt $t5, $a0, $t7
 	beq $t5, $zero, gbc_exit
 	slti $t5, $a1, 0 # check whether y is outside the maze
 	bne $t5, $zero, gbc_exit
 	slt $t5, $a1, $t8
 	beq $t5, $zero, gbc_exit
 	
 	div $a0, $t1
 	mflo $t1 # column no. for given x-coordinate
 	div $a1, $t2
 	mflo $t2 # row no. for given y-coordinate
 	
 	# get the cell from the array
 	mult $t3, $t2
	mflo $t3
	add $t3, $t3, $t1 # index of the cell in 1D-array of bitmap

 	la $t0, maze_bitmap
 	add $t0, $t0, $t3
 	lb $v0, 0($t0)
 	jr $ra
 	
gbc_exit:
 	jr $ra
#--------------------------------------------------------------------
# procedure: create_multi_monsters(num)
# @num: the number of monster objects
# Create multiple monster objects
#--------------------------------------------------------------------
create_multi_monsters:
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s5, 12($sp)
	sw $s6, 16($sp)
 	sw $s7, 20($sp)
 	
 	addi $s0, $a0, 0 # number of objects for creation
 	la $t0, monster_base # base id
 	lw $s1, 0($t0) # id of a monster object
 	li $s5, 0 # number of created objects
 	
cmm_be: 
	beq $s5, $s0, cmm_exit # whether num objects were created
	
cmm_iter:
 	jal get_random_path
 	addi $s6, $v0, 0 # x_loc
 	addi $s7, $v1, 0 # y_loc
 	addi $a0, $s5, 0
 	addi $a1, $s6, 0
 	addi $a2, $s7, 0
 	addi $a3, $s1, 0
	jal monster_duplicate_loc
 	bne $v0, $zero, cmm_iter
 	
 	addi $a1, $s6, 0 # x_loc
 	addi $a2, $s7, 0 # y_loc
 	li $v0, 103
 	addi $a0, $s1, 0 # the id of object
 	li $a3, 2 # object type
 	syscall # create object
 	
 	# create next object
 	addi $s5, $s5, 1
 	addi $s1, $s1, 1
 	j cmm_be
 	
cmm_exit:
 	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s5, 12($sp)
 	lw $s6, 16($sp)
 	lw $s7, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: get_random_path
# Get a random location that is a path and is vertically or horizontally
# separated in at least loc_separation pixels from the current location of the bomberman object.
# The x- and y-coordinate of the random location are returned in $v0 and $v1, respectively.
#--------------------------------------------------------------------
get_random_path:
 	la $t0, bomberman_locs
 	lw $t4, 0($t0) # x_loc of bomberman
 	lw $t5, 4($t0) # y_loc of bomberman
 	la $t0, loc_separation
 	lw $t7, 0($t0) # separation distance between bomberman location and random location
 	sub $t8, $zero, $t7 # -ve separation distance
 	
grp_rand: li $v0, 107 # get random path location
 	syscall
 	sub $t2, $v0, $t4 # difference between bomberman xloc and random xloc
 	slt $t3, $t8, $t2 # greater than -ve separation distance
 	beq $t3, $zero, grp_exit
 	slt $t3, $t2, $t7 # less than +ve separation distance
 	beq $t3, $zero, grp_exit
 	sub $t2, $v1, $t5 # difference between bomberman yloc and random yloc
 	slt $t3, $t8, $t2 # greater than -ve separation distance
 	beq $t3, $zero, grp_exit
 	slt $t3, $t2, $t7 # less than +ve separation distance
 	bne $t3, $zero, grp_rand
 	
grp_exit:
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: monster_duplicate_loc(num, x, y, skip_id)
# Check whether the given coordinate (x, y) is equal to the location
# of any one of the first num monster objects (based on the increasing oject IDs).
# The location of the object with ID skip_id is skipped in the checking.
# $v0=1 if the equality has been found, otherwise $v0=0.
#--------------------------------------------------------------------
monster_duplicate_loc:
 	la $t1, monster_base
 	lw $t0, 0($t1) # id of object
 	add $t8, $a0, $zero # remaining number of objects for checking
 	li $t9, 0 # checking result
 	
mdl_be:
 	beq $t8, $zero, mdl_exit # whether num <= 0
 	beq $a3, $t0, mdl_next # skip this object of id equal to skip_id
 	li $v0, 106 # get monster location
 	addi $a0, $t0, 0
 	syscall
 	bne $a1, $v0, mdl_next # x_locs differ
 	bne $a2, $v1, mdl_next # y_locs differ
 	li $t9, 1
 	j mdl_exit
 	
mdl_next: # check next object
 	addi $t8, $t8, -1
 	addi $t0, $t0, 1
 	j mdl_be
 	
mdl_exit:
 	addi $v0, $t9, 0
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: check_monster_collisions
# Check whether the bomberman object collides with a monster object.
# After a collision has been found, skip further
# collision checking for any other monster objects.
# $v0=1 if a collision has been found, otherwise $v0=0.
#--------------------------------------------------------------------
check_monster_collisions:
 	addi $sp, $sp, -32
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s7, 12($sp)
 	sw $s3, 16($sp)
 	sw $s4, 20($sp)
 	sw $s5, 24($sp)
 	sw $s6, 28($sp)
 	
 	la $t0, monster_num
 	lw $s0, 0($t0) # number of objects
 	la $t0, monster_base
 	lw $s1, 0($t0) # id of a monster object
 	
 	la $t0, monster_size
 	lw $s3, 0($t0) # monster object width
 	lw $s4, 4($t0) # monster object height
 	la $s5, bomberman_locs # location of bomberman object
 	la $t0, bomberman_size
 	lw $s6, 0($t0) # bomberman width
 	lw $s7, 4($t0) # bomberman height
 	
cmc_be: 
	beq $s0, $zero, cmc_no_collision # whether num <= 0
 	li $v0, 106 # get location of monster object
 	addi $a0, $s1, 0
 	syscall
 	lw $t0, 0($s5) # x_loc of bomberman object
 	lw $t1, 4($s5) # y_loc of bomberman object
 	
	# Check if the bomberman objec intersects the monster object
	# Load bomberman width and height
	la $t7, bomberman_size
 	lw $s3, 0($t7) # bomberman width
 	lw $s4, 4($t7) # bomberman height
	# Perserve spaces to push register onto the stack
	addi $sp, $sp, -32 # A total of 8 words
	# For bomberman rectangle (RectA)
	sw $t0, 28($sp) # top-left (x-axis)
	sw $t1, 24($sp) # top-left (y-axis)
	add $t2, $s3, $t0 # $t2 = bottom-right (x-axis)
	addi $t2, $t2, -1
	sw $t2, 20($sp) # bottom-right (x-axis)
	add $t3, $s4, $t1 # $t3 = bottom-right (y-axis)
	addi $t3, $t3, -1
	sw $t3, 16($sp) # bottom-right (y-axis)
	# For monster rectangle (RectB)
	sw $v0, 12($sp) # top-left (x-axis)
	sw $v1, 8($sp) # top-left (y-axis)
	add $t4, $s3, $v0 # $t4 = bottom-right (x-axis)
	addi $t4, $t4, -1
	sw $t4, 4($sp) # bottom-right (x-axis)
	add $t5, $s4, $v1
	addi $t5, $t5, -1
	sw $t5, 0($sp) #bottom-right (y-axis)
	# Calling procedure: check intersection
	jal check_intersection
	# Pop the stack to remove the coordinates
	addi $sp, $sp, 32
	
 	# After calling procedure: check_intersection, $v0=0 if the bomberman missed the monster object
 	beq $v0, $zero, cmc_next
 	li $v0, 1
 	j cmc_exit # skip collision checking for other objects
 	
cmc_next:
 	# update next object
 	addi $s0, $s0, -1
 	addi $s1, $s1, 1
 	j cmc_be
 	
cmc_no_collision:
 	li $v0, 0
 	
cmc_exit:
 	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s7, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	lw $s5, 24($sp)
 	lw $s6, 28($sp)
 	addi $sp, $sp, 32
 	jr $ra
#--------------------------------------------------------------------
# procedure: check_intersection(RectA, RectB)
# @RectA: ((x1, y1), (x2, y2))
# @RectB: ((x3, y3), (x4, y4))
# these 8 parameters are passed through stack!
# @params: the coordinates of RectA and RectB are passed through stack.
# In total, 8 words are passed. RectA is followed by RectB, as shown below.
#
# | RectA.topleft_x |
# | RectA.topleft_y |
# | RectA.botrigh_x |
# | RectA.botrigh_y |
# | RectB.topleft_x |
# | RectB.topleft_y |
# | RectB.botrigh_x |
# | RectB.botrigh_y | <-- $sp
# This procedure is to check whether the above two rectangles intersect each other!
# @return $v0=1: true(intersect with each other); 0: false
#--------------------------------------------------------------------
check_intersection:	
	# First condition - whether RectA's left edge is to the right of RectB's right edge
	# Load the coordinates from stack
	lw $t0, 28($sp) # RectA's left edge (x-axis)
	lw $t1, 4($sp) # RectB's right edge (x-axis)
	# Comparison
	slt $t3, $t0, $t1 # RectA is to the right of RectB
	beq $t3, $zero, ci_no
	
	# Second condition - whether RectA's right edge is to the left of RectB's left edge
	# Load the coordinates from stack
	lw $t4, 20($sp) # RectA's right edge (x-axis)
	lw $t5, 12($sp) # RectB's left edge
	# Comparison
	slt $t6, $t5, $t4 # RectA is left to RectB
	beq $t6, $zero, ci_no

	# Third condtion - whether RectA's top edge is below RectB's bottom edge
	# Load the coordinates from stack
	lw $t0, 24($sp) # RectA's top edge (y-axis)
	lw $t1, 0($sp) # RectB's bottom edge (y-axis)
	# Comparison
	slt $t3, $t0, $t1 # RectA is below RectB
	beq $t3, $zero, ci_no
	
	# Fourth condition - whether RecA's bottom edge is above RectB's top edge
	# Load the coordinates from stack
	lw $t4, 16($sp) # RectA's bottom edge (y-axis)
	lw $t5, 8($sp) # RectB's top edge (y-axis)
	# Comparison
	slt $t6, $t5, $t4 # RectA is above RectB
	beq $t6, $zero, ci_no
	
 	# Have intersection
	li $v0, 1 
	jr $ra
	
ci_no: # No intersection
 	li $v0, 0 
 	jr $ra

#--------------------------------------------------------------------
# procedure: end_game
# End the game, $a0=1, user win. $a0=0, user loss.
# $v0=1 if a collision has been found, otherwise $v0=0.
#--------------------------------------------------------------------
end_game:
	bne $a0, $zero, ed_win
	
ed_lose:
 	li $a0, 0 # stop background sound
 	li $a1, 2
 	li $v0, 102
 	syscall
 	li $a0, 2 # play the sound of losing the game
 	li $a1, 0
 	li $v0, 102
 	syscall
 	la $a3, game_lose_text # display game losing message
 	li $a0, -1 # special ID for this text object
 	addi $a1, $zero, 30 # display the message at coordinate (100, 300)
 	addi $a2, $zero, 305
	j ed_end_game
	
ed_win:
 	li $a0, 0 # stop background sound
 	li $a1, 2
 	li $v0, 102
 	syscall
 	li $a0, 3 # play the sound of winning the game
 	li $a1, 0
 	li $v0, 102
 	syscall
 	la $a3, game_win_text # display game winning message
 	li $a0, -2 # special ID for this text object
 	addi $a1, $zero, 40 # display the message at coordinate (40, 300)
 	addi $a2, $zero, 300
 	
ed_end_game:
 	li $v0, 105 # create object of the game winning or losing message
 	syscall
 	# refresh screen
 	li $v0, 101
 	syscall
 	li $v0, 10 # terminate this program
 	syscall
 	
#--------------------------------------------------------------------
# procedure: check_place_bomb
# Check input key to decide whether place the bomb
# The value will be returned in $v0, placing success returns 0, otherwise returns 1
#--------------------------------------------------------------------
check_place_bomb:
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s5, 12($sp)
 	sw $s6, 16($sp)
 	sw $s7, 20($sp)
 	
 	# check bomb timer
 	li $v0, 110 # return 0 if bomb explodes; 1 bomb still exists; 2 bomb not exists
 	syscall
 	beq $v0, 0, cpb_explode
 	beq $v0, 1, cpb_exit
 	
 	la $t0, input_key
 	lw $t1, 0($t0)
 	li $t2, 32 # corresponds to key ' '
 	beq $t1, $t2, cpb_place
 	j cpb_exit
 	
cpb_explode:
	la $t1, bomb_locs
 	lw $a0, 0($t1) # x_locs
 	lw $a1, 4($t1) # y_locs
 	addi $a2, $zero, 0
 	jal update_bitmap_cell
 	j cpb_exit
 	
cpb_place:
 	la $t0, bomb_timer
 	lw $a0, 0($t0)
 	li $v0, 109 # input, bomb timer
 	syscall
 	bne $v0, 0, cpb_exit
 	# change bit map in mips
 	la $t1, bomberman_locs
 	lw $a0, 0($t1) # x_locs
 	lw $a1, 4($t1) # y_locs
 	la $t2, bomb_locs
 	sw $a0, 0($t2) # x_locs
 	sw $a1, 4($t2) # y_locs
 	
 	addi $a2, $zero, 1
 	jal update_bitmap_cell
 	
cpb_exit:
 	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s5, 12($sp)
 	lw $s6, 16($sp)
 	lw $s7, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: update_bitmap_cell(x, y, value)
# Update the bitmap value for the grid cell containing the given pixel coordinate (x, y).
# a0: x
# a1: y
#--------------------------------------------------------------------
update_bitmap_cell:
 	la $t0, grid_cell_size
 	lw $t1, 0($t0) # cell width 
 	lw $t1, 0($t0) # cell width
 	lw $t2, 4($t0) # cell height
 	la $t0, grid_col_num
 	lw $t3, 0($t0)
 	la $t0, maze_size
 	lw $t7, 0($t0) # maze width
 	lw $t8, 4($t0) # maze height
 	li $v0, -1 # initialize the return value to -1
 	
 	slti $t5, $a0, 0 # check whether x is outside the maze
 	bne $t5, $zero, ubc_exit
 	slt $t5, $a0, $t7
 	beq $t5, $zero, ubc_exit
 	slti $t5, $a1, 0 # check whether y is outside the maze
 	bne $t5, $zero, ubc_exit
 	slt $t5, $a1, $t8
 	beq $t5, $zero, ubc_exit
 	
 	div $a0, $t1
	mflo $t1 # column no. for given x-coordinate
 	div $a1, $t2
 	mflo $t2 # row no. for given y-coordinate
 	
 	# get the cell from the array
 	mult $t3, $t2
 	mflo $t3
 	add $t3, $t3, $t1 # index of the cell in 1D-array of bitmap

 	la $t0, maze_bitmap
 	add $t0, $t0, $t3
 	sb $a2, 0($t0)
 	jr $ra
 	
ubc_exit:
 	jr $ra
 	
#--------------------------------------------------------------------
# procedure: check_explosion_collision
# return -1, player died
# return [0,n), remaining monster number
#--------------------------------------------------------------------
check_explosion_collision:
 	addi $sp, $sp, -24
 	sw $ra, 0($sp)
 	sw $s0, 4($sp)
 	sw $s1, 8($sp)
 	sw $s2, 12($sp)
 	sw $s3, 16($sp)
 	sw $s4, 20($sp)
 	la $a0, maze_destroy
 	li $v0, 112 # destroy brick wall
 	syscall
 	
# *****Task5: you need to check the effect of bomb explosion
# You should call procedure: update_bitmap_cell to update destroyed walls.
# You should use syscall 111 to check the status of bomberman and monsters
# Hints:
# Syscall 112 will return the wall's status in each direction. Return values are stored in maze_destroy array.
# (nX, nY, sX, sY, wX, wY, eX, eY): return -1 if no wall destroyed; otherwise return the pixel of the maze.
# *****Your codes start here
	
cec_N: # For North direction
	la $t0, maze_destroy # Get array address
	lw $a0, ($t0) # Get the first element of maze_destroy, i.e. nX
	# Check whether there is a wall destoryed
	addi $t1, $zero, -1
	beq $t1, $a0, cec_S # No wall is destoryed
	# There is wall destoryed 
	addi $t0, $t0, 4 # The second element of the array
	lw $a1, ($t0) # Get the second element of maze_destroy, i.e. nY
	jal update_bitmap_cell # Update destroyed walls
	
cec_S: # For South direction
	la $t0, maze_destroy # Get  array address
	addi $t2, $zero, 2 # $t2 = i
	sll $t2, $t2, 2 # $t2 = 4*i
	add $t3, $t0, $t2 # $t3 = address of maze_destroy[2]
	lw $a0, ($t3) # Get the thrid element of maze_destroy, i.e. sX
	# Check whether there is a wall destroyed
	addi $t1, $zero, -1
	beq $t1, $a0, cec_W # No wall is destoryed
	# There is wall destoryed 
	addi $t4, $zero, 3 # $t4 = i
	sll $t4, $t4, 2 # $t4 = 4 * i
	add $t5, $t0, $t4 # $t5 = address of maze_destroy[3]
	lw $a1, ($t5) # Get the fourth element of maze_destroy, i.e. sY
	jal update_bitmap_cell # Update destroyed walls

cec_W: # For West direction
	la $t0, maze_destroy # Get  array address
	addi $t2, $zero, 4 # $t2 = i
	sll $t2, $t2, 2 # $t2 = 4*i
	add $t3, $t0, $t2 # $t3 = address of maze_destroy[4]
	lw $a0, ($t3) # Get the fifth element of maze_destroy, i.e. wX
	# Check whether there is a wall destroyed
	addi $t1, $zero, -1
	beq $t1, $a0, cec_E # No wall is destoryed
	# There is wall destoryed 
	addi $t4, $zero, 5 # $t4 = i
	sll $t4, $t4, 2 # $t4 = 4 * i
	add $t5, $t0, $t4 # $t5 = address of maze_destroy[5]
	lw $a1, ($t5) # Get the sixth element of maze_destroy, i.e. wY
	jal update_bitmap_cell # Update destroyed walls

cec_E: # For East direction
	la $t0, maze_destroy # Get  array address
	addi $t2, $zero, 6 # $t2 = i
	sll $t2, $t2, 2 # $t2 = 4*i
	add $t3, $t0, $t2 # $t3 = address of maze_destroy[6]
	lw $a0, ($t3) # Get the seventh element of maze_destroy, i.e. eX
	# Check whether there is a wall destroyed
	addi $t1, $zero, -1
	beq $t1, $a0, cec_status # No wall is destoryed
	# There is wall destoryed 
	addi $t4, $zero, 7 # $t4 = i
	sll $t4, $t4, 2 # $t4 = 4 * i
	add $t5, $t0, $t4 # $t5 = address of maze_destroy[7]
	lw $a1, ($t5) # Get the wighth element of maze_destroy, i.e. eY
	jal update_bitmap_cell # Update destroyed walls
	 
cec_status:
	# Check the status of bomberman and monsters
	li $v0, 111 
	syscall
	# Player loss due to bomb explosion
	addi $t1, $zero, -1
	beq $v0, $t1, cec_player_loss
	# Player win due to bomb explosion and all monsters die
	addi $t1, $zero, 0
	beq $v0, $t1, cec_player_win
	# Continue the game
	j cec_exit

cec_player_loss: # Player loss
	addi $a0, $zero, 0
	j end_game
	li $v0, -1
	
cec_player_win: # Player win
	addi $a0, $zero, 1
	j end_game
	li $v0, 0

cec_exit:
# *****Your codes end here

 	lw $ra, 0($sp)
 	lw $s0, 4($sp)
 	lw $s1, 8($sp)
 	lw $s2, 12($sp)
 	lw $s3, 16($sp)
 	lw $s4, 20($sp)
 	addi $sp, $sp, 24
 	jr $ra

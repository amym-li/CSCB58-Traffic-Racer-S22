###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# Student Name: Amy Li, Student Number: 1008434464, UTorID: liamy22
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed) 
# - Display width in pixels: 256 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 
# 
# Basic features that were implemented successfully 
# - Basic feature a/b/c (choose the ones that apply) 
# 
# Additional features that were implemented successfully 
# - Additional feature a/b/c (choose the ones that apply) 
#  
# Link to the video demo 
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible 
# 
# Any additional information that the TA needs to know: 
# - Write here, if any 
#  
######################################################################

.data

mockDisplay:		.space	16384
lane1:			.space 	4128 # 12 by 64
lane2:			.space	4128
lane3:			.space	4128
lane4:			.space 	4128

displayAddress:		.word	0x10008000
displayAddressEnd:	.word	0x1000C000
num_units:		.word	4096

#cycles:			.word 	0
#max_cycles:		.word	1000

# road colors
pavement_color:		.word	0x272f36
white:			.word	0xFFFFFF
center_line_color:	.word	0xa4a4a4
roadside_yellow:	.word	0xfbb236

pbar_border_color:	.word	0x0c8b0c
pbar_color:		.word	0x3dce3d

# car colors
red:		.word	0xFF0000
blue:		.word	0x5b6ee1
window_blue:	.word 	0xbee9fa

#car_starting_pos:	.word	0x10009D70
roadside_collision:	.word	0 # 0 for false, 1 for true

# incoming car positions - top left pixel (in lane displays), speed, ...
# store such that A[0] is closest to spawn point
lane1_cars:	.word	0, 0, 0, 0, 0, 0
lane2_cars:	.word	0, 0, 0, 0, 0, 0
lane3_cars:	.word	0, 0, 0, 0, 0, 0
lane4_cars:	.word	0, 0, 0, 0, 0, 0
max_cars_per_lane:	.word	3

.text

# $s0 = base address of display
# $s1 = base address of mockDisplay
# $s2 = end address of mockDisplay

# $s3 = number of units in the display
# $s4 = number of lives left
# $s5 = current car position (top left pixel)
# $s6 = current speed (1-slow, 2-med, 3-fast)
# $s7 = cycles completed

.globl main

main:
lw $s0, displayAddress	# base address of actual display
la $s1, mockDisplay	# base address of mockDisplay

la $s2, 16384($s1)	# end address of mockDisplay
lw $s3, num_units	# $s2 stores the number of units in display

new_game:
	li $s4, 6		# initialize number of lives to 6
	addi $s5, $s1, 7796	# car starting position in mock display
	li $s6, 1		# starting speed 1
	li $s7, 0		# current cycles = 0
	
	jal DRAW_START_BKGD	# colors in pavement and draws road lines
	jal DRAW_PLAYER_CAR
	jal DRAW_HEARTS
	
	
main_loop: 

	jal ERASE_CAR
	jal ERASE_HEARTS
	
	jal draw_road_lines
	jal draw_white_dashes
	
	jal DRAW_HEARTS
	jal DRAW_PROGRESS_BAR
	
	jal GENERATE_CARS
	
	# keyboard input here
	jal CHECK_KEYPRESS
	
	# draw new car position
	jal DRAW_PLAYER_CAR
	
	# check for collision
	
	# update location of other vehicles
	
	# redraw screen
	jal DISPLAY_SCREEN
	
	# store car speed and then use that to increment cycle count
	add $s7, $s7, $s6
	
	# sleep
	li $v0, 32  
	li $a0, 100
	syscall 
	
	bgt $s7, 1000, end	# CHANGE IF CHANGING MAX CYCLES
	j main_loop

j end

####################################
DISPLAY_SCREEN:
	
	add $t0, $s1, $zero	# $t0 = base address of mockDisplay
	add $t1, $s2, $zero	# $t1 = end address of mockDisplay
	add $t2, $s0, $zero	# $t2 = base address of actual display
	
	display_screen_loop:
		lw $t3, 0($t0)	# $t3 = color code
		sw $t3, 0($t2)
		
		addi $t0, $t0, 4
		addi $t2, $t2, 4
		blt $t0, $t1, display_screen_loop
	jr $ra
	
####################################
CHECK_KEYPRESS:
	li $t0, 0xffff0000 
	lw $t1, 0($t0) 
	beq $t1, 1, keypress_happened
	
keypress_done: jr $ra
	
keypress_happened:
	lw $t2, 4($t0)
	beq $t2, 97, move_left		# respond to 'a'
	beq $t2, 100, move_right	# respond to 'd'
	beq $t2, 119, speed_up		# respond to 'w'
	beq $t2, 115, slow_down		# respond to 's'

move_left:
	add $s5, $s5, -8
	j keypress_done

move_right:
	add $s5, $s5, 8
	j keypress_done
	
speed_up:
	beq $s6, 3, keypress_done
	addi $s6, $s6, 1
	j keypress_done
	
slow_down:
	beq $s6, 1, keypress_done
	addi $s6, $s6, -1
	j keypress_done

####################################
DRAW_PROGRESS_BAR:
	# draws skeleton of progress bar
	lw $t0, pbar_border_color
	li $t8, 0xFFFFFF
	li $t9, 0x000000
	
	sw $t0, 904($s1)
	sw $t0, 1008($s1)
	sw $t0, 1160($s1)
	sw $t0, 1264($s1)
	
	sw $t8, 1000($s1)
	sw $t9, 1004($s1)
	sw $t9, 1256($s1)
	sw $t8, 1260($s1)

	addi $t1, $s1, 652
	li $t2, 0 # i = 0
	pb_loop1:
		sw $t0, 0($t1)
		sw $t0, 768($t1)
		addi $t1, $t1, 4
		addi $t2, $t2, 1
		blt $t2, 25, pb_loop1
	
	# colors in progress
	lw $t0, pbar_color
	addi $t1, $s1, 908
	div $t3, $s7, 40	# CHANGE IF CHANGING MAX CYCLES
	li $t2, 0 # j = 0
	pb_loop2:
		sw $t0, 0($t1)
		sw $t0, 256($t1)
		addi $t1, $t1, 4
		addi $t2, $t2, 1	
		blt $t2, $t3, pb_loop2
	jr $ra

#####################################
ERASE_HEARTS:
	addi $t0, $s1, 528 # top left pixel
	lw $t1, pavement_color
	li $t2, 0 # j = 0
	
erase_hearts_loop:
	sw $t1, 0($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 768($t0)
	sw $t1, 1024($t0)
	sw $t1, 1280($t0)
	addi $t2, $t2, 1
	blt $t2, 25, erase_hearts_loop
	jr $ra
	
DRAW_HEARTS: 
	add $t4, $s4, $zero
	addi $t0, $s1, 528 # top left pixel
	lw $t1, red
	lw $t2, white
	lw $t3, pavement_color
	
hearts_loop:
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t3, 12($t0)
	sw $t1, 256($t0)
	sw $t2, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	sw $t1, 772($t0)
	sw $t1, 776($t0)
	sw $t1, 780($t0)
	sw $t1, 1032($t0)
	sw $t1, 1036($t0)
	sw $t1, 1292($t0)
	
	addi $t4, $t4, -1
	beq $t4, $zero, hearts_done
	
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 272($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 528($t0)
	sw $t1, 532($t0)
	sw $t1, 536($t0)
	sw $t1, 784($t0)
	sw $t1, 788($t0)
	sw $t1, 1040($t0)
	
	addi $t4, $t4, -1
	addi $t0, $t0, 36
	bgt $t4, $zero, hearts_loop
hearts_done:	jr $ra

###################################

GENERATE_CARS:

	addi $sp, $sp, -4	# push $ra
	sw $ra, 0($sp)
	
	la $a0, lane1_cars
	jal generate_in_lane
	
	la $a0, lane2_cars
	jal generate_in_lane
	
	la $a0, lane3_cars
	jal generate_in_lane
	
	la $a0, lane4_cars
	jal generate_in_lane
	
	lw $ra, 0($sp)		# pop $ra
	addi $sp, $sp, 4
	
	jr $ra

generate_in_lane:	
	# $a0 = address of lane array
	add $t9, $a0, $zero
	
	lw $t0, 0($a0)
	lw $t1, 8($a0)
	lw $t2, 16($a0)
	
	# only generates a car if $a0 = 0
	li $v0, 42  
	li $a0, 0  
	li $a1, 1
	syscall
	bne $a0, 0, generate_return
	
	beq $t2, $zero, generate1
	beq $t1, $zero, generate2
	beq $t0, $zero, generate3
generate_return: jr $ra

generate1:
	li $v0, 42  
	li $a0, 0  
	li $a1, 6 # random position [0, 6]
	syscall
	
	sll $a0, $a0, 2 # multiply by 4
	sw $a0, 16($t9)
	
	li $v0, 42  
	li $a0, 0  
	li $a1, 2 # random speed [0, 2]
	syscall
	
	sw $a0, 20($t9)
	j generate_return
	
generate2:
	div $t4, $t2, 48
	ble $t4, 20, generate_return
	
	li $v0, 42  
	li $a0, 0  
	li $a1, 6 # random position [0, 6]
	syscall
	
	sll $a0, $a0, 2 # multiply by 4
	sw $a0, 8($t9)
	
	li $v0, 42  
	li $a0, 0  
	div $t5, $t2, 960 # div by 48 to get rows, then div by 20
	add $a1, $t5, $zero	
	syscall
	
	sw $a0, 12($t9)
	j generate_return

generate3:
	div $t6, $t1, 48
	ble $t6, 20, generate_return
	
	li $v0, 42  
	li $a0, 0  
	li $a1, 6 # random position [0, 6]
	syscall
	
	sll $a0, $a0, 2 # multiply by 4
	sw $a0, 0($t9)
	
	li $v0, 42  
	li $a0, 0  
	div $t5, $t1, 960 # div by 48 to get rows, then div by 20
	add $a1, $t5, $zero	
	syscall
	
	sw $a0, 4($t9)
	j generate_return
		
###################################
DRAW_LLANE_CAR:
	# $a0 = car position
	add $t0, $a0, $zero	# $t0 = car position
	addi $sp, $sp, -4	# push $ra
	sw $ra, 0($sp)
	
	lw $a1, blue	# blue for opponent car
	jal draw_car_rect
	
	addi $a0, $t0, 516
	jal draw_window
	
	addi $a0, $t0, 1540
	jal draw_window
	
	lw $ra, 0($sp)		# pop $ra
	addi $sp, $sp, 4
	
	jr $ra
	
DRAW_RLANE_CAR:
	# $a0 = car position
	add $t0, $a0, $zero	# $t0 = car position
	addi $sp, $sp, -4	# push $ra
	sw $ra, 0($sp)
	
	lw $a1, blue	# blue for opponent car
	jal draw_car_rect
	
	addi $a0, $t0, 772
	jal draw_window
	
	addi $a0, $t0, 1796
	jal draw_window
	
	lw $ra, 0($sp)		# pop $ra
	addi $sp, $sp, 4
	
	jr $ra
	
###################################
DRAW_PLAYER_CAR: # car is 6x11
	addi $sp, $sp, -4	# push $ra
	sw $ra, 0($sp)
	
	add $a0, $s5, $zero
	lw $a1, red		# red for car
	jal draw_car_rect
	
	addi $a0, $s5, 772
	jal draw_window
	
	addi $a0, $s5, 1796
	jal draw_window
	
	lw $ra, 0($sp)		# pop $ra
	addi $sp, $sp, 4
	
	jr $ra
	
draw_car_rect: 
	# $a0 = top left pixel
	# $a1 = color
	li $t3, 0 # i = 0
	draw_car_loop:
		sw $a1, 0($a0)
		sw $a1, 4($a0)
		sw $a1, 8($a0)
		sw $a1, 12($a0)
		sw $a1, 16($a0)
		sw $a1, 20($a0)
		addi $a0, $a0, 256
		addi $t3, $t3, 1
		blt $t3, 11, draw_car_loop # while i < 11
	jr $ra

draw_window: # draws a 2x4 rect
	# $a0 = top left pixel
	lw $t0, window_blue
	sw $t0, 0($a0)
	sw $t0, 4($a0)
	sw $t0, 8($a0)
	sw $t0, 12($a0)
	sw $t0, 256($a0)
	sw $t0, 260($a0)
	sw $t0, 264($a0)
	sw $t0, 268($a0)
	jr $ra

ERASE_CAR: 
	add $t0, $s5, $zero
	lw $t1, pavement_color
	li $t3, 0 # i = 0
erase_car_loop:
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	addi $t0, $t0, 256
	addi $t3, $t3, 1
	blt $t3, 11, erase_car_loop # while i < 11
	jr $ra
	
##############################

DRAW_START_BKGD:
	addi $sp, $sp, -4	# push $ra
	sw $ra, 0($sp)
	
	jal color_pavement
	jal draw_road_lines
	
	add $a0, $zero, $zero
	jal draw_white_dashes
	
	lw $ra, 0($sp)		# pop $ra
	addi $sp, $sp, 4
	
	jr $ra
	
color_pavement: # colors in pavement
	lw $t0, pavement_color # $t0 = grey color code
	add $t1, $s1, $zero	# $t1 = base address of display
	color_pave_loop:
		sw $t0, 0($t1)
		addi $t1, $t1, 4
		blt $t1, $s2, color_pave_loop
	jr $ra

# colors in center line
draw_road_lines:
	lw $t0, center_line_color
	lw $t1, roadside_yellow
	add $t2, $s1, $zero
	
	draw_lines_loop:
		sw $t0, 124($t2)
		sw $t0, 128($t2)
		
		sw $t1, 0($t2)
		sw $t1, 4($t2)
		
		sw $t1, 248($t2)
		sw $t1, 252($t2)
		
		addi $t2, $t2, 256
		
		blt $t2, $s2, draw_lines_loop
	jr $ra
	
# draws white marks
draw_white_dashes:

	# calculate offset
	li $t9, 8
	div $s7, $t9
	mfhi $t9

	lw $t0, white 	# $t0 = white
	lw $t3, pavement_color		# $t3 = grey
	
	ble $t9, 4, white_dash_cond
	# $t9 > 4
	lw $t0, pavement_color		# $t0 = white
	lw $t3, white	# $t3 = grey
	addi $t9, $t9, -4
	
	white_dash_cond:	
		addi $t1, $s1, 64	# $t1 = base address of left set
		addi $t2, $s1, 188	# $t2 = base address of right set
	
		sw $t3, 0($t1)		# left set - colors in first 4 grey
		sw $t3, 256($t1)
		sw $t3, 512($t1)
		sw $t3, 768($t1)
	
		sw $t3, 0($t2)		# right set - colors in first 4 grey
		sw $t3, 256($t2)
		sw $t3, 512($t2)
		sw $t3, 768($t2)
	
		add $t7, $zero, $zero
		beq $t9, 0, dashes_add_offset
		addi $t7, $zero, 256
		beq $t9, 1, dashes_add_offset
		addi $t7, $t7, 256
		beq $t9, 2, dashes_add_offset
		addi $t7, $t7, 256
		beq $t9, 3, dashes_add_offset
		addi $t7, $t7, 256
		beq $t9, 4, dashes_add_offset
	
	dashes_add_offset:
		add $t1, $t1, $t7
		add $t2, $t2, $t7
	
	white_dash_loop:
		sw $t0, 0($t1)		# left set - white
		sw $t0, 256($t1)
		sw $t0, 512($t1)
		sw $t0, 768($t1)
		
		sw $t3, 1024($t1)	# left set - grey
		sw $t3, 1280($t1)
		sw $t3, 1536($t1)
		sw $t3, 1792($t1)
		
		sw $t0, 0($t2)		# right set - white
		sw $t0, 256($t2)
		sw $t0, 512($t2)
		sw $t0, 768($t2)
		
		sw $t3, 1024($t2)	# right set - grey
		sw $t3, 1280($t2)
		sw $t3, 1536($t2)
		sw $t3, 1792($t2)
		
		addi $t1, $t1, 2048
		addi $t2, $t2, 2048
		
		blt $t2, $s2, white_dash_loop
	jr $ra

end:	li $v0, 10
	syscall


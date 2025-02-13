# Appliance.gd
extends Area2D

signal appliance_finished(result_item)

var is_in_use = false
var input_item = null
var output_item = null

func interact(item):
	# This function should be overridden by child classes.
	pass

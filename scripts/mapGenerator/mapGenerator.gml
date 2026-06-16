function restart() {
	with(obj_controller) {
		global.blackScreen = true;
		global.currentLevel = 1;
		generateMap(11+global.currentLevel, 11+global.currentLevel, 2, 8, 10, global.currentLevel);
		with (obj_player) {
			hp = 100;
			arrows = 3;
		}
		global.gameOver = false;
	}
}

function nextLevel() {
	with(obj_controller) {
		global.blackScreen = true;
		global.keyFound = false;
		global.currentLevel++;
		generateMap(11+global.currentLevel, 11+global.currentLevel, 2, 8, 10, global.currentLevel);
	}
}

function cellBelow(x, y) {
	var xPos = floor(x / 32);
	var yPos = floor(y /32);
	if(yPos != obj_controller.h-1) {
		return obj_controller.level[xPos][yPos+1];
	}
	return [-1,-1];
}

function generateMap(levelWidth, levelHeight, roomSize, cutoutSize, iterations, enemyCount) {
	/*
	-1 = nothing
	0 = wall
	1 = free space
	*/
	
	randomize();
	
	layer_destroy_instances(layer_get_id("Floor"));
	layer_destroy_instances(layer_get_id("Exit"));
	layer_destroy_instances(layer_get_id("Stuff"));
	layer_destroy_instances(layer_get_id("Arrows"));
	layer_destroy_instances(layer_get_id("Characters"));
	
	w = levelWidth;
	h = levelHeight;
	iter = iterations;
	minRoomSize = roomSize;
	maxCutoutSize = cutoutSize;
	
	//room_width = 32 * w;
	//room_height = 32 * h;
	resetCells();
	randomDivider();
    cleanMap();
	// if map is defective
	if(!isConnected()) {
		generateMap(levelWidth, levelHeight, roomSize, cutoutSize, iterations, enemyCount);
		return;
	}
	
	for (j = 0; j<h; j++) {
		for (i = 0; i<w; i++) {
			if (level[i][j] == 1) instance_create_layer(i*32, j*32, layer_get_id("Floor"), obj_floor);
			else if (level[i][j] == 0) instance_create_layer(i*32, j*32, layer_get_id("Stuff"), obj_wall);
		}
    }
	
	// place player
	var posX;
	var posY;
	do {
		posX = floor(random(w));
		posY = floor(random(h));
	} until(level[posX][posY]==1);
	//level[posX][posY] = 2;
	with(obj_player) {
		x = posX*32+16;
		y = posY*32+16;
	}

	// place exit door
	do {
		posX = floor(random(w));
		posY = floor(random(h));
	} until(level[posX][posY]==1);
	//level[posX][posY] = 3;
	instance_create_layer(posX*32,posY*32,layer_get_id("Exit"),obj_trapdoor);
	
	// place enemies
	for(i = 0; i<enemyCount; i++) {
		do {
			posX = floor(random(w));
			posY = floor(random(h));
			
		} until(level[posX][posY]==1 && point_distance(posX*32,posY*32,obj_player.x,obj_player.y) >80);
		//level[posX][posY] = 4;
		var enemy_types = [obj_enemy];
		if (global.currentLevel > 3) {
			array_push(enemy_types, obj_enemy);
			array_push(enemy_types, obj_enemy_ram);
		}
		if (global.currentLevel > 5) {
			array_push(enemy_types, obj_enemy_ram);
			array_push(enemy_types, obj_spider);
		}
		if (global.currentLevel > 7) {
			array_delete(enemy_types,0,1)
			array_push(enemy_types, obj_spider);
			array_push(enemy_types, obj_bat);
		}
		if (global.currentLevel > 9) {
			array_push(enemy_types, obj_bat);
		}
		var enemy_type = enemy_types[irandom(array_length(enemy_types)-1)];
		instance_create_layer(posX*32+16,posY*32+24,layer_get_id("Characters"),enemy_type);
	}
	
	// place barrels
	for(i = 0; i<global.currentLevel; i++) {
		show_debug_message(isConnected() ? "Con\n" : "Not Con\n");
		do {
			do {
				posX = floor(random(w));
				posY = floor(random(h));
			} until(level[posX][posY]==1);
			level[posX][posY] = 0;
			var valid = isConnected();
			if(!valid) level[posX][posY] = 1;
		} until(valid);
		instance_create_layer(posX*32+16,posY*32+24,layer_get_id("Stuff"),obj_barrel);
	}
}

function cleanMap() {
  for (i = 0; i<w; i++) {
    for (j = 0; j<h; j++) {
      count = 0;
      if (j!=0 && level[i][j-1]==1) count++;
      if (i!=0 && level[i-1][j]==1) count++;
      if (level[i][j]==1) count++;
      if (i!=w-1 && level[i+1][j]==1) count++;
      if (j!=h-1 && level[i][j+1]==1) count++;
      if (level[i][j]==1 && count==1 || count==2) {
        level[i][j]=0;
      }
    }
  }
  for (i = 0; i<w; i++) {
    for (j = 0; j<h; j++) {
      count = 0;
      if (j!=0 && level[i][j-1]==1) count++;
      if (i!=0 && level[i-1][j]==1) count++;
      if (level[i][j]==1) count++;
      if (i!=w-1 && level[i+1][j]==1) count++;
      if (j!=h-1 && level[i][j+1]==1) count++;
      if (i!=0 && j!=0 && level[i-1][j-1]==1) count++;
      if (i!=w-1 && j!=0 && level[i+1][j-1]==1) count++;
      if (i!=0 && j!=h-1 && level[i-1][j+1]==1) count++;
      if (i!=w-1 && j!=h-1 && level[i+1][j+1]==1) count++;
      if (count==0) {
        level[i][j]=-1;
      }
    }
  }
}

function dfs(pos) {
  if (ds_list_find_index(ds_visited, pos)!=-1) {
    return;
  }
  if (level[pos%w][pos/w] == 0) {
    return;
  }
  ds_list_add(ds_visited, pos);
  if (pos%w != w-1) dfs(pos+1);
  if (pos/w != h-1) dfs(pos+w);
  if (pos%w != 0) dfs(pos-1);
  if (pos/w != 0) dfs(pos-w);
}

function isConnected() {
	ds_visited = ds_list_create();
	ds_list_clear(ds_visited);
	var pos = -1;
	for (i = 0; i<w*h; i++) {
		if (level[i%w][i/w] == 1) {
		pos = i;
		break;
		}
	}
	if (pos != -1) {
		dfs(pos);
	}
	var free = 0;
	for (i = 0; i<w*h; i++) {
		if (level[i%w][i/w] == 1) {
			free++;
		}
	}
	if (free==ds_list_size(ds_visited)) {
		ds_list_destroy(ds_visited);
		return true;
	} else {
		ds_list_destroy(ds_visited);
		return false;
	}
}

function randomDivider() {
  divide(iter, 1, w-2, 1, h-2, 0, true);
}

function cutoutRect(x1, x2, y1, y2) {
  for (i = x1; i<=x2; i++) {
    for (j = y1; j<=y2; j++) {
      level[i][j] = 0;
    }
  }
}

function freeRect(x1, x2, y1, y2) {
  for (i = x1; i<=x2; i++) {
    for (j = y1; j<=y2; j++) {
      level[i][j] = 1;
    }
  }
}

function divide(iter, x1, x2, y1, y2, omit, horizontal) {  
  var cutout = (x2-x1 > maxCutoutSize || y2-y1 > maxCutoutSize) ? false : random(2) < 0.7;
  iter -= floor(random(2));
  if (iter<=0) return;
  var at = 0;
  if (horizontal) {
    if (y2-y1 < minRoomSize*2+2) return;
    do {
		// show_debug_message("overload2\n");
      at = y1 + minRoomSize + floor(random(y2-y1-minRoomSize*2));
    } until (at!=omit);
    var nextOmit = floor(random(x2-x1))+x1;
    for (i = x1; i<=x2; i++) {
      if (i==nextOmit) continue;
      level[i][at] = 0;
    }
    if (at<omit && cutout) {
      cutoutRect(x1, x2, y1, at-1);
      if (!isConnected()) {
        freeRect(x1, x2, y1, at-1);
        divide(iter-1, x1, x2, y1, at-1, nextOmit, false);
      }
    } else {
      divide(iter-1, x1, x2, y1, at-1, nextOmit, false);
      
    }
    if (at>omit && cutout) {
      cutoutRect(x1, x2, at+1, y2);
      if (!isConnected()) {
        freeRect(x1, x2, at+1, y2);
        divide(iter-1, x1, x2, at+1, y2, nextOmit, false);
      }
    } else {
      divide(iter-1, x1, x2, at+1, y2, nextOmit, false);
    }
  } else {
    if (x2 - x1 < minRoomSize*2+2) return;
    do {
		// show_debug_message("overload3\n");
      at = x1 + minRoomSize + floor(random(x2-x1-minRoomSize*2));
    } until (at!=omit);
    nextOmit = floor(random(y2-y1))+y1;
    for (i = y1; i<=y2; i++) {
      if (i==nextOmit) continue;
      level[at][i] = 0;
    }
    divide(iter-1, x1, at-1, y1, y2, nextOmit, true);
    divide(iter-1, at+1, x2, y1, y2, nextOmit, true);
  }
}

function resetCells() {
  for (j = 0; j<h; j++) {
    for (i = 0; i<w; i++) {
      level[i][j] = 0;
    }
  }
  for (j = 1; j<h-1; j++) {
    for (i = 1; i<w-1; i++) {
      level[i][j] = 1;
    }
  }
}

function findPath(origin, destination, ds_path) {
	var xPos = floor(origin.x/32);
	var yPos = floor(origin.y/32);
	var xPosDest = floor(destination.x/32);
	var yPosDest = floor(destination.y/32);
	var cellDest = getCell(xPosDest, yPosDest);
	var cell = getCell(xPos, yPos);
	
	//show_debug_message("cellDest: " + string(cellDest) + "\n");
	//show_debug_message("cell: " + string(cell) + "\n");
	
	ds_list_clear(ds_path);
	ds_todo = ds_list_create();
	ds_visited = ds_map_create();
	ds_cameFrom = ds_map_create();
	ds_adjacents = ds_list_create();
	ds_visited[? cell] = 0;
	ds_list_add(ds_todo, cell);
	
	while(!ds_list_empty(ds_todo)) {
		// show_debug_message("overload5\n");
		var bestCell = undefined;
		var bestValue = infinity;
		var bestIndex = undefined;
		for(var i = 0; i<ds_list_size(ds_todo); i++) {
			var currentCell = ds_list_find_value(ds_todo, i);
			//show_debug_message("curCell: " + string(currentCell) + "\n");
			//show_debug_message("estimate: " + string(estDistance(currentCell, cellDest)) + "\n");
			var estimate = estDistance(currentCell, cellDest);
			if(estimate < bestValue) {
				bestCell = currentCell;
				bestValue = estimate;
				bestIndex = i;
			}
			//show_debug_message("bestCell: " + string(bestCell) + "\n");
		}
		ds_list_delete(ds_todo, bestIndex);
		//show_debug_message("emptyHello: " + string(ds_list_empty(ds_todo) ? "true" : "false") + "\n");
		
		getAdjacents(bestCell);
		for(var i = 0; i<ds_list_size(ds_adjacents); i++) {
			var currentCell = ds_list_find_value(ds_adjacents, i);
			//show_debug_message("currentCell: " + string(currentCell) + "\n");
			if(ds_visited[? currentCell]==undefined || ds_visited[? bestCell]+32 < ds_visited[? currentCell]) {
				ds_visited[? currentCell] = ds_visited[? bestCell]+32;
				ds_cameFrom[? currentCell] = bestCell;
				if(currentCell==cellDest) {
					break;
				}
				ds_list_add(ds_todo, currentCell);
			}
		}
		//show_debug_message("emptyBye: " + string(ds_list_empty(ds_todo) ? "true" : "false") + "\n");
	}
	
	var totalDistance = ds_visited[? cellDest];
	var tracker = cellDest;
	while(tracker != cell && tracker != undefined) {
		ds_list_add(ds_path, tracker);
		tracker = ds_cameFrom[? tracker];
		// show_debug_message("overload");
	}
	
	ds_map_destroy(ds_visited);
	ds_map_destroy(ds_cameFrom);
	ds_list_destroy(ds_todo);
	
	return totalDistance;
}

function estDistance(from, to) {
	var euclidianDistance = point_distance(getXPos(from)*32, getYPos(from)*32, getXPos(to)*32, getYPos(to)*32);
	//show_debug_message("euclide: " + string(euclidianDistance) + "\n");
	//show_debug_message("mapSize: " + string(ds_map_size(ds_visited)) + "\n");
	return ds_visited[? from] + euclidianDistance;
}

function getAdjacents(cell) {
	ds_list_clear(ds_adjacents);
	var col = getXPos(cell);
	var row = getYPos(cell);
	if(col != 0 && isFree(col-1, row)) {
		ds_list_add(ds_adjacents, cell-1);
	}
	if(col != obj_controller.w-1 && isFree(col+1, row)) {
		ds_list_add(ds_adjacents, cell+1);
	}
	if(row != 0 && isFree(col, row-1)) {
		ds_list_add(ds_adjacents, cell-obj_controller.w);
	}
	if(row != obj_controller.h-1 && isFree(col, row+1)) {
		ds_list_add(ds_adjacents, cell+obj_controller.w);
	}
}

function isFree(col, row) {
	return (obj_controller.level[col][row]!=-1 && obj_controller.level[col][row]!=0)
}

/*function findPath(destination) {
	var xPos = x/32;
	var yPos = y/32;
	var xPosDest = destination.x/32;
	var yPosDest = destination.y/32;
	var cellDest = getCell(xPosDest, yPosDest);
	var cell = getCell(xPos, yPos);
	
	ds_visited = ds_map_create();
	ds_cameFrom = ds_map_create();
	ds_todo = ds_list_create();
	ds_visited[? cell] = 0;
	ds_list_add(ds_todo, cell);
	
	var dist = astar(cell, cellDest);
	
	ds_map_destroy(ds_visited);
	ds_map_destroy(ds_cameFrom);
	ds_list_destroy(ds_todo);
	
	return dist;
}

function astar(cell, cellDest) {
	if(cell == cellDest) {
		return ds_visited[? cellDest];
	}
	if(obj_controller.level[getXPos(cell)][getYPos(cell)] != 1) {
		return;
	}
	var shortestDist = infinity;
	var cellShortest;
	ds_list_delete(ds_todo, ds_list_find_index(ds_todo, cell));
	
	var xx = getXPos(cell);
	var yy = getYPos(cell);
	if(xx != 0 && (is_undefined(ds_visited[? cell - 1]) || ds_visited[? cell-1] > ds_visited[? cell] + 1)) ds_list_add(ds_todo, cell-1);
	if(xx != obj_controller.w-1 && (is_undefined(ds_visited[? cell+1]) || ds_visited[? cell+1] > ds_visited[? cell] + 1)) ds_list_add(ds_todo, cell+1);
	if(yy != 0 && (is_undefined(ds_visited[? cell - obj_controller.w]) || ds_visited[? cell-obj_controller.w] > ds_visited[? cell] + 1)) ds_list_add(ds_todo, cell-obj_controller.w);
	if(yy != obj_controller.h-1 && (is_undefined(ds_visited[? cell+obj_controller.w]) || ds_visited[? cell+obj_controller.w] > ds_visited[? cell] + 1)) ds_list_add(ds_todo, cell+obj_controller.w);
	
	for(var i = 0; i<ds_list_size(ds_todo); i++) {
		var c = ds_list_find_value(ds_todo, i);
		var curDist = estDistance(ds_visited[? cell], c, cellDest);
		if(curDist < shortestDist) {
			shortestDist = curDist;
			cellShortest = c;
		}
	}
	ds_visited[? cellShortest] = ds_visited[? cell] + 32;
	return astar(cellShortest, cellDest);
}

function estDistance(currentDist, cell, cellDest) {
	var dist = currentDist;
	dist += point_distance(getXPos(cell), getYPos(cell), getXPos(cellDest), getYPos(cellDest));
	return dist;
}*/

/*function astar(pos, dest, ds_visited, ds_todo) {
	if(ds_list_add(ds_visited, pos) != -1) {
		return;
	}
	if(obj_controller.level[getXPos(pos)][getYPos(pos)] != 1) {
		return;
	}
	ds_list_add(ds_visited, pos);
	if(pos == dest) {
		return;
	}
	var xx = getXPos(pos);
	var yy = getYPos(pos);
	if(xx != 0) ds_queue_enqueue(ds_todo, pos-1);
	if(xx != obj_controller.w-1) ds_queue_enqueue(ds_todo, pos+1);
	if(yy != 0) ds_queue_enqueue(ds_todo, pos-obj_controller.w);
	if(yy != obj_controller.h-1) ds_queue_enqueue(ds_todo, pos+obj_controller.w);
}*/

function getXPos(cell) {
	return floor(cell % obj_controller.w);
}

function getYPos(cell) {
	return floor(cell / obj_controller.w);
}

function getCell(xPos, yPos) {
	return yPos * obj_controller.w + xPos;
}



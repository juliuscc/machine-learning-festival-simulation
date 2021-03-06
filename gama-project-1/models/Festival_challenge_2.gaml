/**
* Name: FestivalGuest
* Author: hrabo, jcelik
* Description: 
* Tags: 
*/

model Festival

global {
	init
	{
		// Make sure we get consistent behaviour
		seed<-10.0;
		
		create FestivalGuest number: 20
		{
			location <- {rnd(100),rnd(100)};
//			dangerous <- flip(0.05);
		}
				
		create FestivalGuard number: 1 {
			location <- {rnd(100),rnd(100)};
			speed <- 1.0;
		}
				
//		int add_dist <- 0;
//		int d_dist <- 60;
		bool make_drink_store <- true;
		create FestivalStore number: 4
		{
//			location <- {10 + add_dist, 10 + add_dist};
			location <- {rnd(100), rnd(100)};
//			add_dist <- add_dist + d_dist;
			
			if (make_drink_store)
			{
				hasDrinks <- true;
				hasFood <- false;
				myColor <- #purple;
				
			} else {
				hasDrinks <- false;
				hasFood <- true;
				myColor <- #green;
			}
			
			make_drink_store <- not make_drink_store;
		}
		
		create FestivalInformationCenter number: 1
		{
			location <- {50, 50};
		}
		
	}
}

species FestivalGuard skills: [moving] {
	FestivalGuest target;
	
	reflex wander when: target = nil {
		speed <- 1.0;
		do wander;
	}
	
	reflex chase_target when: target != nil {
		speed <- 2.5;


//		write "Chasing!";
		do goto target:target;

		ask FestivalGuest at_distance 2 {
			if (self.dangerous) {
				write "Killed violating guest!";
				do die;
			}
			myself.target <- nil;
		}
	}
	
	aspect default {
//		draw sphere(4) at: location color: #black;

		
		draw pyramid(5) at: {location.x, location.y, 0} color: #black;
    	draw sphere(3) at: {location.x, location.y, 6} color: #black;
	}
}

species FestivalStore {
	rgb myColor <- #blue;
	
	bool hasDrinks <- false;
	bool hasFood <- false;
	
	aspect default {
		draw cube(10) at: location color: myColor ;
    }
}

species FestivalInformationCenter {
	rgb myColor <- #yellow;
	
	list<FestivalStore> drink_stores;
	list<FestivalStore> food_stores;
	
	init {
		ask FestivalStore {
			if (self.hasDrinks) {
				myself.drink_stores << self;
			}
			if (self.hasFood) {
				myself.food_stores << self;
			}
		}
	}
	
	reflex check_for_danger {
		ask FestivalGuest at_distance 30 {
			if (self.dangerous) {
				ask FestivalGuard {
					if (self.target = nil)
					{
						self.target <- myself;	
					}
				}
			}
		}
	}
	
	aspect default{
		draw pyramid(10) at: location color: myColor ;
    }
    
}

species FestivalGuest skills: [moving] {
	rgb myColor <- #red;
	int max_food_and_drink_level <- 400;
	
	FestivalStore target_store;
	point target_point;
	
	int drink_level <- rnd(max_food_and_drink_level);
	int food_level <- rnd(max_food_and_drink_level);
	
	bool dangerous <- false;
	
	reflex beIdle when: drink_level > 0 and food_level > 0 and target_store = nil and target_point = nil
	{
		if (not dangerous)
		{
			dangerous <- flip(0.0005);
		}
		
		myColor <- #red;
		do wander;
	}
	
	reflex go_to_target when: target_store != nil
	{
		do goto target:target_store;
		ask FestivalStore at_distance 2 {
			if (self.hasDrinks) {
				myself.drink_level <- myself.max_food_and_drink_level;
			}
			if (self.hasFood) {
				myself.food_level <- myself.max_food_and_drink_level;
			}
		}
		
		if (drink_level > 0 and food_level > 0) {
			target_store <- nil;
			target_point <- {rnd(100), rnd(100)};
		}
	}
	
	reflex go_to_dance_target when: drink_level > 0 and food_level > 0 and target_store = nil and target_point != nil
	{
		myColor <- #red;
		do goto target:target_point; 
	}
	
	reflex enter_dance_mode when: drink_level > 0 and food_level > 0 and target_store = nil and target_point != nil
	{
		if (location distance_to (target_point) < 2)
		{
			target_point <- nil;
		}	
	}
	
	// Make sure the agent will do something when it gets thirsty
	reflex inquire_resource_location when: (drink_level <= 0 or food_level <= 0) and (target_store = nil)
	{		
		myColor <- #yellow;
		
		do goto target:{50,50};
		ask FestivalInformationCenter at_distance 2 {
			if(myself.drink_level <= 0) {
				int count <- length(self.drink_stores);
				int index <- rnd(count - 1);
				
				myself.target_store <- self.drink_stores[index];
				myself.myColor <- #purple;
			} else if (myself.food_level <= 0) {
				int count <- length(self.food_stores);
				int index <- rnd(count - 1);
				
				myself.target_store <- self.food_stores[index];
				myself.myColor <- #green;
			}
		}
	}
	
	// make more thirsty or hungry
	reflex consume_resources when: drink_level > 0 and food_level > 0
	{
		// More hunger
		if (flip(0.5)) {
			food_level <- food_level - 1;
		// More thirst
		} else {
			drink_level <- drink_level - 1;
		}
	}
		
	aspect default {
		if (dangerous) {
			myColor <- #black;
		}
		
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
    }
}

/*Running the experiment*/
experiment main type: gui {
	output {
		display map type: opengl 
		{
			species FestivalGuest;
			species FestivalStore;
			species FestivalInformationCenter;
			species FestivalGuard;
		}
//		display chart
//		{
//			chart "Agent information"
//			{
//				data "Agents blue color" value:length(FestivalGuest where (each.myColor = #blue));
//				data "Have met another blue" value:length(FestivalGuest where (each.haveMet = true));
//			}
//		}
	}
}



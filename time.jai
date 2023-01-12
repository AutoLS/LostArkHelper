Clock :: struct
{
	performance_frequency: s64;
	sec_per_count: float;
	
	last_count: s64;
	end_count: s64;
	counter_elapsed: s64;
	
	t: float;
}

Timer :: struct
{
	t: float;
	t_end: float;
	t_def: float;
	
	active: bool;
	complete: bool;
}

init_clock :: () -> Clock
{
	result: Clock;
	QueryPerformanceFrequency(*result.performance_frequency);
	result.sec_per_count = 1.0 / cast(float) result.performance_frequency;
	QueryPerformanceCounter(*result.last_count);
	
	return result;
}

get_seconds_elapsed :: (clock: *Clock) -> float
{
	result := (cast(float)(clock.end_count - clock.last_count) * clock.sec_per_count);
	
	return result;
}

get_seconds_elapsed :: (last_count: s64, current_count: s64, sec_per_count: float) -> float
{
	result := (cast(float)(current_count - last_count) * sec_per_count);
	
	return result;
}

update_clock :: (clock: *Clock)
{
	clock.t = get_seconds_elapsed(clock);
	clock.counter_elapsed = clock.end_count - clock.last_count;
	clock.last_count = clock.end_count;
}

lock_fps :: (clock: *Clock, targetFPS: float)
{
	if targetFPS > 0 
	{
		current_count: s64;
		QueryPerformanceCounter(*current_count);
		
		frameCompleteTime := 
		get_seconds_elapsed(clock.last_count, current_count, clock.sec_per_count);
		
		targetSecPerFrame := 1.0 / targetFPS;
		
		if(frameCompleteTime < targetSecPerFrame)
		{
			sleepTime := cast(int)((targetSecPerFrame - frameCompleteTime) * 1000) - 1;
			if sleepTime > 0
			{
				Sleep(cast(s32)sleepTime);
			}
			
			QueryPerformanceCounter(*current_count);
			while get_seconds_elapsed(clock.last_count, current_count, clock.sec_per_count) 
				  < targetSecPerFrame
			{
				QueryPerformanceCounter(*current_count);
			}
		}
	}
	
	QueryPerformanceCounter(*clock.end_count);
}

get_fps :: (clock: Clock) -> float
{
	if clock.counter_elapsed == 0 
	{
		return -1;
	}
	
	result := cast(float)clock.performance_frequency / cast(float) clock.counter_elapsed;
	return result;
}

create_timer :: (t_end: float, active: bool) -> Timer
{
	timer: Timer;
	timer.t_end = t_end;
	timer.t_def = t_end;
	timer.active = active;
	
	return timer;
}

start_timer :: (timer: *Timer)
{
	timer.active = true;
}

stop_timer :: (timer: *Timer)
{
	timer.active = false;
}

reset_timer :: (timer: *Timer)
{
	timer.t = 0;
	timer.complete = false;
}

reset_and_stop_timer :: (timer: *Timer)
{
	reset_timer(timer);
	stop_timer(timer);
}

reset_and_start_timer :: (timer: *Timer)
{
	reset_timer(timer);
	start_timer(timer);
}

process_timer :: (timer: *Timer, t: float)
{
	if timer.active
	{
		timer.t += t;
		if timer.t >= timer.t_end && timer.t_end > 0
		{
			timer.complete = true;
			stop_timer(timer);
		}
		else if timer.t_end == 0
		{
			timer.complete = true;
		}
	}
}
function set_tick_timestamps(axes, use_milliseconds, sttime)

%% Find nice round numbers to use
number_of_ticks = 6;
x_lim = xlim(axes);
xrange = x_lim(2) - x_lim(1);
xrange = xrange / number_of_ticks;
nice = floor(log10(xrange));
frac = 1;
if nice > 1
    frac = 4;
end
nice = round(xrange * frac / 10^nice) / frac * 10^nice;

%x_tick = floor(x_lim(1)):nice:ceil(x_lim(2));
x_tick = x_lim(1):nice:x_lim(2);
x_tick_days = x_tick / (24*60*60);
if isa(sttime,'datetime')
    if ~use_milliseconds
        sttime = datetime(sttime,'Format','yyyy-MM-dd HH:mm:ss');
    end
    labels = cellstr(x_tick_days + sttime)';
else
    x_tick_hours = fix(x_tick / 3600);
    x_tick_minutes = fix(((x_tick / 3600) - x_tick_hours) * 60);
    x_tick_seconds = ((((x_tick / 3600) - x_tick_hours) * 60) - x_tick_minutes) * 60;
    
    if use_milliseconds
            labels = compose('%.0f:%.0f:%05.2f', x_tick_hours', x_tick_minutes', x_tick_seconds');
    else
            labels = compose('%.0f:%.0f:%04.1f', x_tick_hours', x_tick_minutes', x_tick_seconds');
    end
end

x_tick=x_tick(1,2:end-1);
labels=labels(2:end-1,1);

xticks(axes, x_tick)
xticklabels(axes,labels);
end


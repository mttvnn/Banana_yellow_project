function [walking_period] = activity_detection(activity)
% Filtering the activities smaller than 60s
walking_period = zeros(size(activity));
i = 1;
while i <= length(activity)
    if activity(i)
        count = 0;
        while (i + count <= length(activity)) && activity(i + count)
            count = count + 1;
        end
        if count > 59
            walking_period(i : i + count - 1) = 1;
        end
        i = i + count;
    else
        i = i + 1;
    end
end


end
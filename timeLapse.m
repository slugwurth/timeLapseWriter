classdef  timeLapse
    % Time Lapse Writer
    % Matt Ireland 2020
    
    % This largely wraps the matlab VideoWriter class and scripts dir
    % search, looping etc
    
    % Pass an output filename and framerate to the constructor to produce
    % an uncompressed avi video
    
    properties
        video
    end
    
    methods
        function obj = timeLapse(outputFilename,framerate)
            % Class Constructor
            obj.video = outputFilename;
            % Initialize output file
            v = VideoWriter(outputFilename,'Uncompressed AVI', 'FrameRate', framerate);
            open(v);
            
            % Grab current directory contents
            list = dir;
            
            % Add files sequentially
            for ii = 3:size(list,1)
                a = imread(list(ii).name);
                writeVideo(v,a);
            end
            
            % close the file
            close(v);
        end
    end
end


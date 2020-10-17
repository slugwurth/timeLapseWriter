classdef  timeLapse
    % Time Lapse Writer
    % Matt Ireland 2020
    
    % This largely wraps the matlab VideoWriter class and scripts dir
    % search, looping etc
    
    % Pass an output filename and framerate to the constructor to produce
    % a lossless avi video
    
    properties
        name
        imageNames
        frate
    end
    
    % Class Constructor
    methods
        function obj = timeLapse(outputFilename,frate)
            
            obj.name = outputFilename;
            obj.frate = frate;
            
            % Grab current directory contents
            iNames = dir(fullfile(pwd,'*.jpg'));
            obj.imageNames = {iNames.name}';
            
            % Compile video
            obj = compileVideo(obj);
        end
    end
    
    % Future capabilities
    methods 
        
        function obj = compileVideo(obj)
            % Initialize output file
            outputVideo = VideoWriter(fullfile(pwd,obj.name));
            outputVideo.FrameRate = obj.frate;
            open(outputVideo)
            
            % Add files sequentially
            for ii = 1:length(obj.imageNames)
                disp(['Frame ' num2str(ii) ' of ' num2str(length(obj.imageNames))]);
                img = imread(fullfile(pwd,obj.imageNames{ii}));
                writeVideo(outputVideo,img)
            end
            
            % close the file
            close(outputVideo);

        end
    end
end


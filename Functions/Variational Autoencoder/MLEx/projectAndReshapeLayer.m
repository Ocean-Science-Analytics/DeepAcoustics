classdef projectAndReshapeLayer < nnet.layer.Layer ...
        & nnet.layer.Formattable ...
        & nnet.layer.Acceleratable

    properties
        % Layer properties.
        OutputSize
    end

    properties (Learnable)
        % Layer learnable parameters.

        Weights
        Bias
    end

    methods
        function layer = projectAndReshapeLayer(outputSize,NameValueArgs)
            % layer = projectAndReshapeLayer(outputSize)
            % creates a projectAndReshapeLayer object that projects and
            % reshapes the input to the specified output size.
            %
            % layer = projectAndReshapeLayer(outputSize,Name=name)
            % also specifies the layer name.

            % Parse input arguments.
            arguments
                outputSize
                NameValueArgs.Name = "";
            end

            % Set layer name.
            name = NameValueArgs.Name;
            layer.Name = name;

            % Set layer description.
            layer.Description = "Project and reshape to size " + ...
                join(string(outputSize));

            % Set layer type.
            layer.Type = "Project and Reshape";

            % Set output size.
            layer.OutputSize = outputSize;
        end

        function layer = initialize(layer,layout)
            % layer = initialize(layer,layout) initializes the layer
            % learnable parameters.
            %
            % Inputs:
            %         layer  - Layer to initialize
            %         layout - Data layout, specified as a 
            %                  networkDataLayout object
            %
            % Outputs:
            %         layer - Initialized layer

            % Layer output size.
            outputSize = layer.OutputSize;

            % Initialize fully connect weights.
            if isempty(layer.Weights)

                % Find number of channels.
                idx = finddim(layout,"C");
                numChannels = layout.Size(idx);

                % Initialize using Glorot.
                sz = [prod(outputSize) numChannels];
                numOut = prod(outputSize);
                numIn = numChannels;
                layer.Weights = initializeGlorot(sz,numOut,numIn);
            end

            % Initialize fully connect bias.
            if isempty(layer.Bias)

                % Initialize with zeros.
                layer.Bias = initializeZeros([prod(outputSize) 1]);
            end
        end

        function Z = predict(layer, X)
            % Forward input data through the layer at prediction time and
            % output the result.
            %
            % Inputs:
            %         layer - Layer to forward propagate through
            %         X     - Input data, specified as a formatted dlarray
            %                 with a "C" and optionally a "B" dimension.
            % Outputs:
            %         Z     - Output of layer forward function returned as
            %                 a formatted dlarray with format "SSCB".

            % Fully connect.
            weights = layer.Weights;
            bias = layer.Bias;
            X = fullyconnect(X,weights,bias);

            % Reshape.
            outputSize = layer.OutputSize;
            Z = reshape(X,outputSize(1),outputSize(2),outputSize(3),[]);
            Z = dlarray(Z,"SSCB");
        end
    end
end
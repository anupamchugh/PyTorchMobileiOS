#import "TorchModule.h"
#import <LibTorch/LibTorch.h>

@implementation TorchModule {
 @protected
  torch::jit::script::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
  self = [super init];
  if (self) {
    try {
      auto qengines = at::globalContext().supportedQEngines();
      if (std::find(qengines.begin(), qengines.end(), at::QEngine::QNNPACK) != qengines.end()) {
        at::globalContext().setQEngine(at::QEngine::QNNPACK);
      }
      _impl = torch::jit::load(filePath.UTF8String);
      _impl.eval();
    } catch (const std::exception& exception) {
      NSLog(@"%s", exception.what());
      return nil;
    }
  }
  return self;
}

- (NSInteger)predictImage:(void*)imageBuffer forLabels:(NSInteger)labelCount {
    int outputLabelIndex = -1;
    try {
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, 224, 224}, at::kFloat);
    torch::autograd::AutoGradMode guard(false);
    at::AutoNonVariableTypeMode non_var_type_mode(true);
    auto outputTensor = _impl.forward({tensor}).toTensor();
    float* floatBuffer = outputTensor.data_ptr<float>();
    if (!floatBuffer) {
      return outputLabelIndex;
    }

    float maxPredictedValue = 0.0f;
    for (int i = 1; i < labelCount; i++) {
        
        if(floatBuffer[i] > maxPredictedValue) {
            maxPredictedValue = floatBuffer[i];
            outputLabelIndex = i;
        }
    }
      return outputLabelIndex;
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return outputLabelIndex;
}

@end


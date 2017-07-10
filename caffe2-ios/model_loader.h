#pragma once

typedef enum
{
	ModelType_GPU,
	ModelType_CPU,
}
ModelType;

class ModelDataStore;
class ModelLoader
{
public:
	ModelLoader();
	virtual ~ModelLoader();

public:
	bool loadProtoBuffer(char*& protoBuffer, unsigned long& protoBufferSize, ModelType modelType = ModelType_GPU);
	bool loadModelBuffer(char*& modelBuffer, unsigned long& modelBufferSize, ModelType modelType = ModelType_GPU);

private:
	ModelDataStore* _dataStore;
};


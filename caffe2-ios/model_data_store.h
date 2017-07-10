#pragma once

#include <string>

class ModelDataStore
{
public:
	ModelDataStore();
	~ModelDataStore();

public:
//	std::string modelDataString();
	std::string modelDataString_cpu();

//	void protoData(char*& protoDataBuffer, unsigned long& protoDataSize);
	void protoData_cpu(char*& protoDataBuffer, unsigned long& protoDataSize);

private:
//	std::string _modelData;
	std::string _modelData_cpu;
};


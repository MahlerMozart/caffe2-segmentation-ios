#include "model_loader.h"
#include "model_data_store.h"
#include "AES.h"

#include <stdio.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>

typedef unsigned char byte;

byte key1[] = { 0x6A, 0x29, 0x5B, 0x95,
0xCC, 0x5D, 0xD6, 0x9A,
0xC5, 0x31, 0x8B, 0x62,
0x4E, 0xF5, 0x72, 0xFC
};

byte key2[] = { 0xE2, 0x39, 0x1A, 0x9D,
0xCD, 0xD2, 0x27, 0x81,
0x05, 0x0C, 0xA7, 0x3D,
0x53, 0x89, 0x6E, 0x9C
};

ModelLoader::ModelLoader()
{
	_dataStore = new ModelDataStore();
}


ModelLoader::~ModelLoader()
{
	delete _dataStore;
}

int string2Bytes(unsigned char* szSrc, unsigned char* pDst, int nDstMaxLen);


bool ModelLoader::loadProtoBuffer(char*& protoBuffer, unsigned long& protoBufferSize, ModelType modelType)
{
	//�����ַ�����ʽ
	/*
	std::string protoString = _dataStore->protoDataString();
	const char* protoStringBuffer = protoString.c_str();
	int protoStringLen = protoString.length();
	char* protoBufferTemp = (char*)malloc(protoStringLen / 2);
	unsigned long protoBufferSizeTemp = 0;

	//����С�ڴ����ת������
	int srcBufLen = 2048; //������Ҫ���������
	int dstBufLen = srcBufLen / 2;
	char* srcBuffer = (char*)malloc(srcBufLen + 1);
	char* dstBuffer = (char*)malloc(dstBufLen);
	int bufferIdx = 0;
	int lineIndex = 0;
	CAES encryptor(key2);

	while (bufferIdx < protoStringLen)
	{
		memset(srcBuffer, 0, srcBufLen + 1);
		memset(dstBuffer, 0, dstBufLen);

		int copyLen = (protoStringLen - bufferIdx) < srcBufLen ? (protoStringLen - bufferIdx) : srcBufLen;
		memcpy(srcBuffer, protoStringBuffer + bufferIdx, copyLen);
		bufferIdx += copyLen;

		int bufferLen = string2Bytes((unsigned char*)srcBuffer, (unsigned char*)dstBuffer, dstBufLen);
		if (bufferLen <= 0)
		{
			std::cout << "string2Bytes error bufferLen:" << bufferLen << std::endl;
			break;
		}

		if (lineIndex < 2)
		{
			//����
			encryptor.Decrypt(dstBuffer, dstBufLen);
			if (dstBufLen != bufferLen)
			{
				std::cout << "Decrypt len error" << std::endl;
			}
		}
		lineIndex++;

		memcpy(protoBufferTemp + protoBufferSizeTemp, dstBuffer, bufferLen);
		protoBufferSizeTemp += bufferLen;
	}
	free(srcBuffer);
	free(dstBuffer);

	if (protoBufferSizeTemp != protoStringLen / 2)
	{
		std::cout << "loadModelBuffer error modelBufferSize:" << protoBufferSizeTemp << " should be:" << protoStringLen / 2 << std::endl;
		free(protoBufferTemp);
		return false;
	}
	protoBuffer = protoBufferTemp;
	protoBufferSize = protoBufferSizeTemp;

	return true;

	//��С�ڴ������ʽ
	int protoLen = protoString.length();
	int maxBufferSize = protoLen / 2;
	char* protoBufferTemp = (char*)malloc(maxBufferSize);
	int protoBufferSizeTemp = string2Bytes((unsigned char*)protoString.c_str(), (unsigned char*)protoBufferTemp, maxBufferSize);
	if (protoBufferSizeTemp == 0)
	{
	std::cout << "string2Bytes error protoBufferSize:" << protoBufferSizeTemp << std::endl;
	return false;
	}
	protoBuffer = protoBufferTemp;
	protoBufferSize = protoBufferSizeTemp;

	*/

	//�������鷽ʽ
	char* protoBufferTemp = NULL;
	unsigned long protoBufferSizeTemp = 0;
//	if (modelType == ModelType_GPU)
//	{
//		_dataStore->protoData(protoBufferTemp, protoBufferSizeTemp);
//	}
//	else
//	{
//		_dataStore->protoData_cpu(protoBufferTemp, protoBufferSizeTemp);
//	}
    _dataStore->protoData_cpu(protoBufferTemp, protoBufferSizeTemp);
	//����
	CAES encryptor(key1);
	int bufferSize = 1024;
	char* decryptBuffer = (char*)malloc(bufferSize);
	if (protoBufferTemp != NULL && bufferSize * 2 < protoBufferSizeTemp)
	{
		for (int i = 0; i < 2; i++)
		{
			memcpy(decryptBuffer, protoBufferTemp + bufferSize*i, bufferSize);
			encryptor.Decrypt(decryptBuffer, bufferSize);
			memcpy(protoBufferTemp + bufferSize*i, decryptBuffer, bufferSize);
		}
	}
	free(decryptBuffer);

	protoBuffer = protoBufferTemp;
	protoBufferSize = protoBufferSizeTemp;

	return true;



}

bool ModelLoader::loadModelBuffer(char*& modelBuffer, unsigned long& modelBufferSize, ModelType modelType)
{
	std::string modelString;
//	if (modelType == ModelType_GPU)
//	{
//		modelString = _dataStore->modelDataString();
//	}
//	else
//	{
//		modelString = _dataStore->modelDataString_cpu();
//	}

    modelString = _dataStore->modelDataString_cpu();

	const char* modelStringBuffer = modelString.c_str();
	int modelStringLen = modelString.length();
	char* modelBufferTemp = (char*)malloc(modelStringLen / 2);
	unsigned long modelBufferSizeTemp = 0;

	//����С�ڴ����ת������
	int srcBufLen = 2048; //������Ҫ���������
	int dstBufLen = srcBufLen / 2;
	char* srcBuffer = (char*)malloc(srcBufLen + 1);
	char* dstBuffer = (char*)malloc(dstBufLen);
	int bufferIdx = 0;
	int lineIndex = 0;
	CAES encryptor(key2);

	while (bufferIdx < modelStringLen)
	{
		memset(srcBuffer, 0, srcBufLen + 1);
		memset(dstBuffer, 0, dstBufLen);

		int copyLen = (modelStringLen - bufferIdx) < srcBufLen ? (modelStringLen - bufferIdx) : srcBufLen;
		memcpy(srcBuffer, modelStringBuffer + bufferIdx, copyLen);
		bufferIdx += copyLen;

		int bufferLen = string2Bytes((unsigned char*)srcBuffer, (unsigned char*)dstBuffer, dstBufLen);
		if (bufferLen <= 0)
		{
			std::cout << "string2Bytes error bufferLen:" << bufferLen << std::endl;
			break;
		}

		if (lineIndex < 2)
		{
			//����
			encryptor.Decrypt(dstBuffer, dstBufLen);
			if (dstBufLen != bufferLen)
			{
				std::cout << "Decrypt len error" << std::endl;
			}
		}
		lineIndex++;

		memcpy(modelBufferTemp + modelBufferSizeTemp, dstBuffer, bufferLen);
		modelBufferSizeTemp += bufferLen;
	}
	free(srcBuffer);
	free(dstBuffer);

	if (modelBufferSizeTemp != modelStringLen / 2)
	{
		std::cout << "loadModelBuffer error modelBufferSize:" << modelBufferSizeTemp << " should be:" << modelStringLen / 2 << std::endl;
		free(modelBufferTemp);
		return false;
	}
	modelBuffer = modelBufferTemp;
	modelBufferSize = modelBufferSizeTemp;
	

	//_dataStore->modelData(modelBuffer, modelBufferSize);

	return true;
}

#pragma warning(disable:4996)
int string2Bytes(unsigned char* szSrc, unsigned char* pDst, int nDstMaxLen)
{
	if (szSrc == NULL)
	{
		return 0;
	}
	int iLen = (int)strlen((char *)szSrc);
	if (iLen <= 0 || iLen % 2 != 0 || pDst == NULL || nDstMaxLen < iLen / 2)
	{
		return 0;
	}

	iLen /= 2;
//	_strupr((char *)szSrc);

	for (int i = 0; i<iLen; i++)
	{
		int iVal = 0;
		unsigned char *pSrcTemp = szSrc + i * 2;
		sscanf((char *)pSrcTemp, "%02x", &iVal);
		pDst[i] = (unsigned char)iVal;
	}

	return iLen;
}

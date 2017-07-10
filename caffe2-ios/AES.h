#ifndef _AES_H_
#define _AES_H_

#include <cstdio>

typedef unsigned char BYTE;
#define IN
#define OUT
class CAES
{
public:
    /*
    * ��  �ܣ���ʼ��
    * ��  ����key �� ��Կ��������16�ֽ�(128bit)
    */
    CAES(const BYTE key[16]);
    ~CAES();

    /*
     * ��  �ܣ����ܣ����ܺ���ֽڴ�����ֻ����16�ֽڵ�������
     * ��  ����src_data �� ��Ҫ���ܵ��ֽڴ���������Ϊ��
     *        src_len �� src_data���ȣ�������Ϊ0
     *        dst_data �� ָ����ܺ��ֽڴ���ָ�룬�����ָ��Ϊ�ջ���dst_lenС�ڼ��ܺ�������ֽڳ��ȣ������ڲ����Զ�����ռ�
     *        dst_len �� dst_data����
     *        release_dst �� �����ڲ��Զ�����ռ�ʱ�Ƿ�ɾ�����пռ�
     * ����ֵ: �����ֽڴ�����
     */
    size_t Encrypt(IN const void* const src_data, IN size_t src_len, OUT void*& dst_data, IN size_t dst_len, IN bool release_dst = false);

    /*
    * ��  �ܣ�����
    * ��  ����data �� [IN] ��Ҫ���ܵ��ֽڴ���������Ϊ��
    *                [OUT]���ܺ���ֽڴ�
    *        len �� �ֽڴ����ȣ��ó��ȱ�����16�ֽ�(128bit)��������
    */
    void Decrypt(IN OUT void* data, IN size_t len);

    /*
    * ��  ��: ��ȡ�����ܵ��ֽڴ������ܺ��ֽڳ���
    * ��  ��: src_len �� ��Ҫ���ܵ��ֽڴ�����
    * ����ֵ: ���ܺ��ֽڴ����� 
    */
    size_t GetEncryptDataLen(IN size_t src_len) const;

private:
    // ��dataǰ16�ֽڽ��м���
    void Encrypt(BYTE* data);
    // ��dataǰ16�ֽڽ��н���
    void Decrypt(BYTE* data);
    // ��Կ��չ
    void KeyExpansion(const BYTE* key);
    BYTE FFmul(BYTE a, BYTE b);
    // ����Կ�ӱ任
    void AddRoundKey(BYTE data[][4], BYTE key[][4]);
    // �����ֽ����
    void EncryptSubBytes(BYTE data[][4]);
    // �����ֽ����
    void DecryptSubBytes(BYTE data[][4]);
    // ��������λ�任
    void EncryptShiftRows(BYTE data[][4]);
    // ��������λ�任
    void DecryptShiftRows(BYTE data[][4]);
    // �����л����任
    void EncryptMixColumns(BYTE data[][4]);
    // �����л����任
    void DecryptMixColumns(BYTE data[][4]);

private:
    BYTE* encrypt_permutation_table_;   // �����û���
    BYTE* decrypt_permutation_table_;   // �����û���
    BYTE round_key_[11][4][4];          // ����Կ
};

#endif // !_AES_H_
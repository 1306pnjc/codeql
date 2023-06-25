#include <iostream>
#include <vector>
#include "zlib.h"
int SafeRead() {
    std::cout << "enter compressed file name!\n" << std::endl;
    char fileName[100];
    std::cin >> fileName;
    gzFile inFileZ = gzopen(fileName, "rb");
    if (inFileZ == nullptr) {
        printf("Error: Failed to gzopen %s\n", fileName);
        exit(0);
    }
    unsigned char unzipBuffer[8192];
    unsigned int unzippedBytes;
    uint totalRead = 0;
    std::vector<unsigned char> unzippedData;
    while (true) {
        unzippedBytes = gzread(inFileZ, unzipBuffer, 8192);
        totalRead += unzippedBytes;
        if (unzippedBytes > 0) {
            unzippedData.insert(unzippedData.end(), unzipBuffer, unzipBuffer + unzippedBytes);
            if (totalRead > 1024 * 1024 * 4) {
                std::cout << "Bombs!" << totalRead;
                exit(1);
            } else {
                std::cout << "not Bomb yet!!" << totalRead << std::endl;
            }
        } else {
            break;
        }
    }

    for (auto &&i: unzippedData)
        std::cout << i;
    gzclose(inFileZ);

    return 0;
}
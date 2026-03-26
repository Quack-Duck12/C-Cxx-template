#include <stdio.h>

int main(){
    printf("Hello World!\n");

    #ifdef _DEBUG //For debug purposes
        printf("Hello Debug!\n");
    #endif
}
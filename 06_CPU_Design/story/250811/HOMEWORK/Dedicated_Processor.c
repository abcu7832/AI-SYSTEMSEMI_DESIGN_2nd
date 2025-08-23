#include<stdio.h>

int main() {
	int a = 0;
	int sum = 0;
	int output = 0;

	while (a <= 10) {
		output = sum;
		a = a + 1;
		sum = sum + a;
	}
	return 0;
}

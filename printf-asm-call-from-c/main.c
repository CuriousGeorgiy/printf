void printf(const char *, ...);

int main()
{
	printf("I %s %x %d %% %c %b %s, but I %s %x %d %% %c %b\xA", "love", 3802, 100, 33, 255, "meow", "love", 3802, 1488, 33, 255);

	return 0;
}

typedef unsigned long long int UINT;
typedef unsigned short    USHORT;
typedef unsigned long     LONG;

typedef unsigned long     DWORD;
typedef unsigned short    WORD;

typedef char TCHAR;

#define MAKEWORD(a, b) ((WORD)(((BYTE)(a)) | ((WORD)((BYTE)(b))) << 8))
#define MAKELONG(a, b) ((LONG)(((WORD)(a)) | ((DWORD)((WORD)(b))) << 16))
#define LOWORD(l) ((WORD)(l))
#define HIWORD(l) ((WORD)(((DWORD)(l) >> 16) & 0xFFFF))
#define LOBYTE(w) ((BYTE)(w))
#define HIBYTE(w) ((BYTE)(((WORD)(w) >> 8) & 0xFF))

#define MAKELPARAM MAKELONG

#define TEXT(x) (x)

#define WINAPI __stdcall

#define EXPORT __attribute__((visibility("default")))

#define _CRT_SECURE_NO_DEPRECATE
#include <stdio.h>
#include <stdlib.h>

// Function to print a matrix stored in a 1D array
void print_matrix(unsigned* matrix, unsigned rows, unsigned cols, FILE* file);
// Function to read matrix from a file
void read_matrix(const char* filename, unsigned** matrix, unsigned* rows, unsigned* cols);
// Function to read kernel from a file
void read_kernel(const char* filename, unsigned** kernel, unsigned* k);
// Function to write output matrix to a file
void write_output(const char* filename, unsigned* output, unsigned rows, unsigned cols);
// Initialize output as zeros.
void initialize_output(unsigned*, unsigned, unsigned);

int main() {

    unsigned n, m, k;  // n = rows of matrix, m = cols of matrix, k = kernel size
    // Dynamically allocate memory for matrix, kernel, and output
    unsigned* matrix = NULL;  // Input matrix
    unsigned* kernel = NULL;  // Kernel size 3x3
    unsigned* output = NULL;  // Max size of output matrix

    char matrix_filename[30];
    char kernel_filename[30];

    // Read the file names
    printf("Enter matrix filename: ");
    scanf("%s", matrix_filename);
    printf("Enter kernel filename: ");
    scanf("%s", kernel_filename);


    // Read matrix and kernel from files
    read_matrix(matrix_filename, &matrix, &n, &m);  // Read matrix from file
    read_kernel(kernel_filename, &kernel, &k);      // Read kernel from file

    // For simplicity we say: padding = 0, stride = 1
    // With this setting we can calculate the output size
    unsigned output_rows = n - k + 1;
    unsigned output_cols = m - k + 1;
    output = (unsigned*)malloc(output_rows * output_cols * sizeof(unsigned));
    initialize_output(output, output_rows, output_cols);

    // Print the input matrix and kernel
    printf("Input Matrix: ");
    print_matrix(matrix, n, m, stdout);

    printf("\nKernel: ");
    print_matrix(kernel, k, k, stdout);

    /******************* KODUN BU KISMINDAN SONRASINDA DEĞİŞİKLİK YAPABİLİRSİNİZ - ÖNCEKİ KISIMLARI DEĞİŞTİRMEYİN *******************/

    // Assembly kod bloğu içinde kullanacağınız değişkenleri burada tanımlayabilirsiniz. ---------------------->
    // Aşağıdaki değişkenleri kullanmak zorunda değilsiniz. İsterseniz değişiklik yapabilirsiniz.
    unsigned matrix_value, kernel_value;    // Konvolüsyon için gerekli 1 matrix ve 1 kernel değişkenleri saklanabilir.
    unsigned sum;                           // Konvolüsyon toplamını saklayabilirsiniz.
    unsigned matrix_offset;                 // Input matrisi üzerinde gezme işleminde sınırları ayarlamak için kullanılabilir.
    unsigned tmp_si, tmp_di;                // ESI ve EDI döngü değişkenlerini saklamak için kullanılabilir.
    unsigned size_byte;
    //unsigned kernel_index;     ////
    unsigned tmp_k;

    size_byte = 4;  /// her eleman 4 byte yer kaplıyor, adres hesaplamada kullanmak için 
    matrix_offset = k / 2;
    sum = 0; 
    //kernel_index = 0;   //
    tmp_k = 0;

    // Assembly dilinde 2d konvolüsyon işlemini aşağıdaki blokta yazınız ----->
    __asm {
         MOV tmp_si, 0  //sum'ın yazılacağı output matrisin satırı ve aynı zamanda her bir kaydırma ve çarpma işleminde input matrisin başlangıç noktası
         MOV ECX, output_rows    
L1 :     PUSH ECX
         MOV ECX, output_cols    
         MOV tmp_di, 0  //sum'ın yazılacağı output matrisin sütunu ve aynı zamanda her bir kaydırma ve çarpma işleminde input matrisin başlangıç noktası
L2 :     PUSH ECX
         MOV sum, 0
         XOR ESI, ESI  //o anki elemanın başlangıç satırından kaç satır sonra geldiğini tutar
         XOR EDI, EDI // o anki elemanın başlangıç sütunundan kaç sütun sonra geldiğini tutar 
         MOV tmp_k, 0  //3. loopta kernel'ın kaçıncı elemanında olduğunu tutmak için
         MOV EAX, k
         MUL EAX
         MOV ECX, EAX  // 3. loop kernel'ın eleman sayısı kadar sürmeli
         JMP L3

L2_V2 :  LOOP L2  //127 byte'lık jump sınırı aşıldığı için 
L1_V2 :  LOOP L1

L3:      XOR EDX, EDX     
         MOV EAX, tmp_k    //kernel[((ESI*k)+EDI)*4]
         DIV k    
         MOV ESI, EAX   //kernel elemanın sırası k'ya böldündüğünde bölüm row değerini
         MOV EDI, EDX   //kalan column değerini verir
         
         MOV EAX, tmp_k 
         MUL size_byte  //her eleman 4 byte yer kapladığı için sıra değeriyle çarpılır
         MOV EBX, kernel
         MOV EAX, [EBX+EAX] //dizinin başlangıç adresine eklenir
         MOV kernel_value, EAX

         MOV EAX, tmp_si  // matrix[(((tmp_si+ESI)*m)+tmp_di+EDI)*4]
         ADD EAX, ESI 
         MUL m
         ADD EAX, tmp_di
         ADD EAX, EDI
         MUL size_byte    //EAX = matrix[(((tmp_si+ESI)*m)+tmp_di+EDI)*4]
         MOV EBX, matrix
         MOV EAX, [EBX+EAX]      //EAX = matrix value
         MUL kernel_value
         ADD sum, EAX

         INC tmp_k
         LOOP L3

         MOV EAX, tmp_si   //output[((tmp_si*output_cols)+tmp_di)*4]
         MUL output_cols
         ADD EAX, tmp_di
         MUL size_byte
         MOV EBX, output
         ADD EBX, EAX   //EBX = output[((tmp_si*output_cols)+tmp_di)*4]
         MOV EAX, sum
         MOV[EBX], EAX   ////output[((tmp_si*output_cols)+tmp_di)*4] = sum

         POP ECX
         INC tmp_di
         CMP ECX, 1 //ECX 1'den büyükse loop devam eder 1'e eşitse loop'u tamamlamıştır
         JA L2_V2  //L2 out of range olduğu için önce L2_V2'ye jump yaptırıyorum orada L2'ye geçiyor

         POP ECX
         INC tmp_si
         CMP ECX, 1  //ECX 1'den büyükse loop devam eder 1'e eşitse loop'u tamamlamıştır
         JA L1_V2  //L1 out of range olduğu için önce L1_V2'ye jump yaptırıyorum orada L2'ye geçiyor
    }

    /******************* KODUN BU KISMINDAN ÖNCESİNDE DEĞİŞİKLİK YAPABİLİRSİNİZ - SONRAKİ KISIMLARI DEĞİŞTİRMEYİN *******************/


    // Write result to output file
    write_output("./output.txt", output, output_rows, output_cols);

    // Print result
    printf("\nOutput matrix after convolution: ");
    print_matrix(output, output_rows, output_cols, stdout);

    // Free allocated memory
    free(matrix);
    free(kernel);
    free(output);

    return 0;
}

void print_matrix(unsigned* matrix, unsigned rows, unsigned cols, FILE* file) {
    if (file == stdout) {
        printf("(%ux%u)\n", rows, cols);
    }
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            fprintf(file, "%u ", matrix[i * cols + j]);
        }
        fprintf(file, "\n");
    }
}

void read_matrix(const char* filename, unsigned** matrix, unsigned* rows, unsigned* cols) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error opening file %s\n", filename);
        exit(1);
    }

    // Read dimensions
    fscanf(file, "%u %u", rows, cols);
    *matrix = (unsigned*)malloc(((*rows) * (*cols)) * sizeof(unsigned));

    // Read matrix elements
    for (int i = 0; i < (*rows); i++) {
        for (int j = 0; j < (*cols); j++) {
            fscanf(file, "%u", &(*matrix)[i * (*cols) + j]);
        }
    }

    fclose(file);
}

void read_kernel(const char* filename, unsigned** kernel, unsigned* k) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error opening file %s\n", filename);
        exit(1);
    }

    // Read kernel size
    fscanf(file, "%u", k);
    *kernel = (unsigned*)malloc((*k) * (*k) * sizeof(unsigned));

    // Read kernel elements
    for (int i = 0; i < (*k); i++) {
        for (int j = 0; j < (*k); j++) {
            fscanf(file, "%u", &(*kernel)[i * (*k) + j]);
        }
    }

    fclose(file);
}

void write_output(const char* filename, unsigned* output, unsigned rows, unsigned cols) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        printf("Error opening file %s\n", filename);
        exit(1);
    }

    // Write dimensions of the output matrix
    fprintf(file, "%u %u\n", rows, cols);

    // Write output matrix elements
    print_matrix(output, rows, cols, file);

    fclose(file);
}

void initialize_output(unsigned* output, unsigned output_rows, unsigned output_cols) {
    int i;
    for (i = 0; i < output_cols * output_rows; i++)
        output[i] = 0;
    
}


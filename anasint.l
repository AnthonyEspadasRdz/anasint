%{
/*
    Programa :
    
        Analizador lexico-Sintactico para un lenguaje definido
    
    Desarollado por:

        Espadas Rodriguez Anthony Jonathan - 421033621
        Santiago Martinez Ricardo          - 318187251

    Asignatura:                     Ciclo escolar:

        Compiladores                    2024-1

    Profesora:

        M.C. Laura Sandoval Montaño
*/    

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Archivos para indicar estado del analisis
FILE* salida;   // Archivo con los tokens generados
FILE* errores;  // Registro de errores encontrados
FILE* tablas;   // Visualiza el estado final de las tablas
FILE* tokens;   // Muestra la entrada que genera los tokens
FILE* atomicas; // Guarda la cadena de atomicas para el analsis sintactico

// Alias de tipo para las estructuras usadas
typedef struct _token TOKEN;
typedef struct _nodo NODO;
typedef struct _lista LISTA;
typedef struct _lista_T LISTA_T;

// Estructura para generar las tablas
struct _lista{
    int clase;      // Clase de elementos que contiene
    NODO* head;     // Primer elemento de la tabla
};

// Estructura para guardar valores en las tablas
struct _nodo{
    char* cad;      // Simbolo que representa
    int valor;      // Posicion en la tabla
    int tipo;       // Determina el tipo cuando se guardan identificadores
    NODO* siguiente;// Apuntado al siguiente elemento
};

// Estructura para almacenar los tokens
struct _lista_T {
    TOKEN* head;    // Apunta el primer token
    TOKEN* tail;    // Apunta al ultimo token
};

// Estructura generada al identificar un componente lexico valido
struct _token{
    int clase;       // Tipo de tabla a la que pertenece
    int valor;       // Posicion que ocupa en la tabla
    TOKEN* siguiente;// Siguiente token en orden
};

/*********** Tipo de componente segun indices de la tabla en el arreglo **********************
 0 - Operadaores aritmeticos
 1 - Operadores logicos
 2 - Operadores relacionales
 3 - Constantes numericas enteras
 4 - Palabras reservadas
 5 - Identificadores
 6 - Simbolos especiales
 7 - Operadores de asignacion
 8 - Constantes cadenas"
 9 - Operadores sobre cadenas
***********************************************************************************************/

LISTA* listas[10];          // Arreglo que guarda las tablas generadas
LISTA_T* tokens_L;          // Estructura que guarda los tokens generados

char* cadena;               // Guardara la cadena de atomicas para usarse en tiempo de ejecucion

int contador_cadenas = 0;   // Contador auxiliar para llevar control del indice de la tabla de cadenas
int contador_lineas = 1;    // Contador auxiliar para llevar un control del numero de lineas analizadas
int contador_tokens = 0;    // Lleva un control de los tokens generados
int contador_atomos = 0;    // lleva un control de los atomos generados

// Prototipos de funciones
LISTA* crearLista(int clase);
NODO* crearNodo(char* cad, int valor);
TOKEN* crearToken(int clase, int valor);
int esVacia(LISTA* lista);
void buscaNombre(int clase);
char* copiarCadena(char* yytext, int yyleng);
void agregarEntrada(LISTA* lista, char* cad);
void verificarEntrada(LISTA* lista, char* cad);
void generarToken(int clase, int valor);
void agregarToken(int clase, char* yytext, int yyleng);
void generarTablas();
int encontrarValor(LISTA* lista, char* cad);
void imprimirTokens();
void imprimirLista(LISTA* lista);
void imprimirTablas();
void liberarMemoria();
void vaciarLista(LISTA* lista);
void vaciarTokens();
char* generarAtomicas();

%}

dig     [0-9]
let     [a-zA-Z]
salto   \n
espacio " "|{salto}|\t
signo   [\-+]
oparit  {signo}|[*/%]
simbesp [\(\)\{\};,\[\]:#]
palres  assinado|caso|enquanto|fazer|flutuador|inteiro|para|quebrar|retorno|se|trocar
ident   _{let}({let}|{dig}|_)*
num     {dig}+
consnum {num}|\({signo}{num}\)
cadena  \"[^\"]*\"
oprel   [<>]|[<>!=]=
oplog   !|(&|\|){2}
opcad   &|like
opasig  {oparit}?=
misigno ({let}|{dig})+

%%
{oparit}    {fprintf(salida,"\n%s  ==> genera token ==> ", yytext);
                                    agregarToken(0, yytext, yyleng);}   // Se agrega correspondiente al componente

{oplog}     {fprintf(salida,"\n%s  ==> genera token ==> ", yytext);
                                    agregarToken(1, yytext, yyleng);}   // Se agrega correspondiente al componente

{oprel}     {fprintf(salida,"\n%s  ==> genera token ==> ", yytext);
                                    agregarToken(2, yytext, yyleng);}   // Se agrega correspondiente al componente

{consnum}   {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                    agregarToken(3, yytext, yyleng);}   // Se agrega correspondiente al componente

{palres}    {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                    agregarToken(4, yytext, yyleng);}   // Se agrega correspondiente al componente

{ident}     {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                   agregarToken(5, yytext, yyleng);}   // Se agrega correspondiente al componente

{simbesp}   {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                    agregarToken(6, yytext, yyleng);}   // Se agrega correspondiente al componente

{opasig}    {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                    agregarToken(7, yytext, yyleng);}   // Se agrega correspondiente al componente

{cadena}    {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                    agregarToken(8, yytext, yyleng);}   // Se agrega correspondiente al componente

{opcad}     {fprintf(salida,"\n%s ==> genera token ==> ", yytext);
                                    agregarToken(9, yytext, yyleng);}   // Se agrega correspondiente al componente

{salto}     {contador_lineas++;}                                        // Se contabiliza el salto de linea

{espacio}   {}                                                          // No se hacen cambios a la secuencia de tokens

{misigno}   {fprintf(salida,"\n%s ==> Elemento no reconocido", yytext);
             fprintf(errores,"Elemento \"%s\" no reconocido en linea %i\n", yytext, contador_lineas);}

.           {fprintf(salida,"\n%s ==> Elemento no reconocido", yytext);
             fprintf(errores,"Elemento \"%s\" no reconocido en linea %i\n", yytext, contador_lineas);}

%%

int main()
{
    // Se inicia la lista de tokens
    tokens_L = (LISTA_T*) malloc(sizeof(LISTA_T));
    tokens_L -> head = tokens_L -> tail = NULL;

    // Abre flujo de datos
    salida = fopen("salida.txt", "w");
    tokens = fopen("tokens.txt", "w");
    errores = fopen("errores.txt", "w");
    //atomicas = fopen("atomicas.txt", "w");
    
    generarTablas();                        // Coloca tabla en estado inicial
    yylex();                                // Inicia analis lexico
    
    imprimirTablas();                       // Guarda el estado final de las tablas
    imprimirTokens();                       // Guarda la secuencia de tokens en un archivo
    
    cadena = generarAtomicas();             // Crea la cadena de atomicas para el analisis sintactico
    //fputs(cadena, atomicas);                // Se guarda en un archivo la cadena de atomicas
    
    // Cierra el flujo de datos
    fclose(salida);
    fclose(tokens);
    fclose(errores);
    //fclose(atomicas);
    
    // anaSint();                              // Comienza el analsis sintactico
    liberarMemoria();                       // Libera el espacio usado

    // Indica el termino del programa
    system("clear");
    printf("\nAnalisis terminao\n");
    printf("\nSe generaron: %i tokens\n", contador_tokens);
    printf("\nEl programa tiene: %i lineas\n", contador_lineas);
    printf("\nLa cadena de atomicas es: \n\t%s\n", cadena);
    return 0;
}

// Almacena el espacio para una lista
LISTA* crearLista(int clase)
{
    LISTA* nueva_lista = (LISTA*) malloc(sizeof(LISTA));    // Reserva el espacio
    nueva_lista -> head = NULL;                             // No asigna inicio
    nueva_lista -> clase = clase;                           // Asigna la clase
    return nueva_lista;                                     // Devuelve la direccion
}

// Almacena espacio para un nodo
NODO* crearNodo(char* cad, int valor)
{

    NODO* nuevo_nodo  = (NODO*) malloc(sizeof(NODO));   // Reserva memoria
    nuevo_nodo -> cad = cad;                            // Coloca simbolo
    nuevo_nodo -> valor = valor;                        // Indica valor correspondiente
    nuevo_nodo -> tipo = -1;                            // Se coloca el valor por defecto del tipo
    nuevo_nodo -> siguiente = NULL;
    return nuevo_nodo;  
}

// Reserva espaco para el token a partir de los datos leidos
TOKEN* crearToken(int clase, int valor)
{
    TOKEN* nuevo_token = (TOKEN*) malloc(sizeof(TOKEN));
    nuevo_token -> clase = clase;
    nuevo_token -> valor = valor;
    nuevo_token -> siguiente = NULL;
    contador_tokens++;                                      // Se incrementa el contador de tokens
    return nuevo_token;
}

// Cadena que copia la cadena apuntada por yytext para validaciones
char* copiarCadena(char* yytext, int yyleng)
{
    char* c_aux = (char*) malloc(sizeof(char)*yyleng);  // Reservamos memoria según el tamaño
    strncpy(c_aux, yytext, yyleng);                     // Copiamos el valor
    c_aux[yyleng] = '\0';                               // añadimos el fin de cadena
    return c_aux;
}

// Determina si la lista cuenta con elementos
int esVacia(LISTA* lista)
{
    if(lista -> head == NULL)
        return 1;
    
    return 0;
}

// Encuentra el valor de una entrada de la tabla
int encontrarValor(LISTA* lista, char* cad)
{
    NODO* nodo_aux = lista -> head;     // Nodo de apoyo a las comparaciones

    // Evita buscar en tablas vacias
    if(nodo_aux == NULL)
        return -1;
    
    // Recorre la tabla comparando el valor leido con su entrada
    while (nodo_aux != NULL)
    {
        if(!strcmp(nodo_aux -> cad, cad))
            return nodo_aux -> valor;   // Devuelve el valor asignado cuando encuentra una coincidencia

        nodo_aux = nodo_aux -> siguiente;
    }

    return -1;                          // No hubo coincidencias
}

// Verifica si una entrada pertenece a una tabla
void verificarEntrada(LISTA* lista, char* cad)
{
    // Una lista vacia no verifica
    if(esVacia(lista))
    {
        agregarEntrada(lista, cad);
        return;
    }

    int existe = 0;                         // Bandera para verificar coincidencia
    NODO* nodo_aux = lista -> head;         // Nodo de apoyo para verificar

    while(nodo_aux != NULL)
    {
        // Realiza la comparacion con el id en la entrada
        if(!strcmp(nodo_aux -> cad, cad))
        {
            existe = 1;
            break;
        }

        nodo_aux = nodo_aux -> siguiente;   // Nos desplazamos en la tabla
    }

    // Si se encendio la bandera, el elemento ya existe
    if(existe)
        return;
    
    agregarEntrada(lista, cad);             // Si no se encendio, es un nuevo elemento
}

// Agrega una entrada a la tabla
void agregarEntrada(LISTA* lista, char* cad)
{
    int valor = 0;

    // Caso para lista vacia
    if(esVacia(lista))
    {
        lista -> head = crearNodo(cad, valor);
    }
    else
    {
        NODO* nodo_aux = lista -> head;                 // Nodo auxiliar el recorrido
        valor++;                                        // Por cada elemento recorrido, el valor en la tabla aumenta

        // Recorre hasta el ultimo elemento
        for(; nodo_aux -> siguiente != NULL; nodo_aux = nodo_aux -> siguiente)
            valor++;

        nodo_aux -> siguiente = crearNodo(cad, valor);  // Se coloca el nodo cuando se llega el final
    }
}

// Coloca todas las tablas en su estado inicial
void generarTablas()
{
    // Reserva la memoria para cada lista
    for(int i = 0; i < 10; i++)
    {
        listas[i] = crearLista(i);
    }

    // Agregado de elementos en la tabla 1
    agregarEntrada(listas[1], "&&");
    agregarEntrada(listas[1], "||");
    agregarEntrada(listas[1], "!");

    // Agregado de elementos en la tabla 2
    agregarEntrada(listas[2], "==");
    agregarEntrada(listas[2], "!=");
    agregarEntrada(listas[2], ">");
    agregarEntrada(listas[2], "<");
    agregarEntrada(listas[2], ">=");
    agregarEntrada(listas[2], "<=");

    // Agregado de elementos en la tabla 4
    agregarEntrada(listas[4], "assinado");
    agregarEntrada(listas[4], "caso");
    agregarEntrada(listas[4], "enquanto");
    agregarEntrada(listas[4], "fazer");
    agregarEntrada(listas[4], "flutuador");
    agregarEntrada(listas[4], "inteiro");
    agregarEntrada(listas[4], "para");
    agregarEntrada(listas[4], "quebrar");
    agregarEntrada(listas[4], "retorno");
    agregarEntrada(listas[4], "se");
    agregarEntrada(listas[4], "trocar");

    // Agregado de elementos en la tabla 7  
    agregarEntrada(listas[7], "=");
    agregarEntrada(listas[7], "+=");
    agregarEntrada(listas[7], "-=");
    agregarEntrada(listas[7], "*=");
    agregarEntrada(listas[7], "/=");
    agregarEntrada(listas[7], "%=");

    // Agregado de elementos en la tabla 9
    agregarEntrada(listas[9], "&");
    agregarEntrada(listas[9], "like");
}

// Agrega el token a la coleccion
void generarToken(int clase, int valor)
{
    TOKEN* token_aux = crearToken(clase, valor);    // Reserva el espacio para los nuevos datos
    
    // Cuando no hay tokens
    if(tokens_L -> head == NULL)
    {
        // Se le colocan ambas referencias
        tokens_L -> head = token_aux;
        tokens_L -> tail = token_aux;
    }
    // Cuando hay un token
    else if (tokens_L -> head == tokens_L -> tail)
    {
        tokens_L -> tail = token_aux;               // El nuevo token se mueve al final
        tokens_L -> head -> siguiente = token_aux;  // Se encadena con el inicio
    }
    // Cuando hay 2 o mas tokens
    else
    {
        tokens_L -> tail -> siguiente = token_aux;  // El nuevo token se mueve al final
        tokens_L -> tail = token_aux;               // El nuevo token se mueve al final
    }
}

// Toma el componente lexico identificado y genera el token correspondiente
void agregarToken(int clase, char* yytext, int yyleng)
{
    char* c_aux = copiarCadena(yytext, yyleng);                 // Cadena auxiliar para validar entrada
    int indice;                                                 // Guarda la posicion de los tokens que usan tablas

    // Modifica la cadena segun el tipo de componente identificadp
    switch(clase)
    {
        case 0:
        case 6:
            generarToken(clase, (int) *c_aux);                  // Se genera token con el ascii leido
            fprintf(salida,"(%i, %i)", clase, (int) *c_aux);    // Se visualiza el valor en la salida
            break;
        case 3:
            // Verifica si es signado
            if(c_aux[0] == '(')
            {   
                // Omite el primer parentesis
                c_aux[0] = c_aux[1];
                c_aux[1] = '0';

                // Si es positivo, omite el signo
                if(c_aux[0] == '+')
                    c_aux[0] = '0';
                
                // Omite el segundo parentesis
                c_aux[yyleng-1] = '.';
            }
            
            generarToken(clase, atoi(c_aux));                   // Genera el token numerico usando la cadena
            fprintf(salida,"(%i, %i)", clase, atoi(c_aux));     // Se visualiza el valor en la salida
            break;
        case 8:
            agregarEntrada(listas[8], c_aux);                   // Se agrega la cadena a la tabla
            generarToken(8, contador_cadenas);                  // Se genera el token para su referencia
            fprintf(salida,"(8, %i)", contador_cadenas);        // Se visualiza el valor en la salida
            contador_cadenas++;                                 // El contador de cadenas aumenta
            break;
        case 5:
            verificarEntrada(listas[5], c_aux);                 // Verifica si el identificador existe
        default:
            indice = encontrarValor(listas[clase], c_aux);      // Encuentra velor del identificador en la tabla
            generarToken(clase, indice);                        // Genera token usando valor
            fprintf(salida,"(%i, %i)", clase, indice);          // Se visualiza el valor en la salida
    }
}

// Guarda la secuencia de tokens en un archivo
void imprimirTokens()
{
    TOKEN* token_aux = tokens_L -> head;    // Nodo auxiliar que recorrera la lista

    // Se detiene al pasar todos los tokens
    while(token_aux != NULL)
    {
        fprintf(tokens,"(%i,%i)\n", token_aux -> clase, token_aux -> valor);
        fflush(tokens);
        token_aux = token_aux -> siguiente;
    }
}

// Coloca todas las tablas en un archivo
void imprimirTablas()
{
    tablas = fopen("tablas.txt","w");   // Abrimos flujo de datos

    // Recorre el arreglo de listas para imprimirlas
    for(int i = 0; i < 10; i++)
    {
        // Omitimos las clases sin registros
        if (i == 0|i == 3|i == 6)
            continue;

        LISTA* aux = listas[i];         // Tomamos la tabla
        
        // Imprimimos su encabezado
        fprintf(tablas,"\nTabla %i - ", aux -> clase);
        buscaNombre(aux -> clase);
        fprintf(tablas,"Valor\tSimbolo");

        // La tabla 5 tambien muestra el tipo de identificador
        if (i == 5)
            fprintf(tablas,"\t\tTipo");

        fprintf(tablas,"\n");           // Fin de los encabezados
        imprimirLista(listas[i]);       // Imprimimos sus elementos
    }

    fclose(tablas);                     // Cerramos flujo de datos
}

// Impreme todos los nodos de una lista
void imprimirLista(LISTA* lista)
{
    // Se omiten las listas sin elementos
    if(esVacia(lista))
        return;
    
    NODO* nodo_aux = lista -> head; // Si hay almenos uno, se continua
    
    // Imprime el valor de cada nodo y se recorre
    while(nodo_aux != NULL)
    {
        fprintf(tablas,"%i\t\t%s", nodo_aux -> valor, nodo_aux -> cad);

        // Para la tabla 5 tambien se imprime el tipo
        if (lista -> clase == 5)
            fprintf(tablas,"\t\t%i", nodo_aux -> tipo);

        fprintf(tablas,"\n");       // Fin de la linea

        nodo_aux = nodo_aux -> siguiente;
    }        
}

// Imprime cadena correspondiente a tabla
void buscaNombre(int clase)
{
    switch(clase)
    {
        case 1:
            fprintf(tablas,"Operadores logicos\n");
            break;
        case 2:
            fprintf(tablas,"Operadores relacionales\n");
            break;
        case 4:
            fprintf(tablas,"Palabras reservadas\n");
            break;
        case 5:
            fprintf(tablas,"Identificadores\n");
            break;
        case 7:
            fprintf(tablas,"Operadores de asignacion\n");
            break;
        case 8:
            fprintf(tablas,"Constantes cadenas\n");
            break;
        case 9:
            fprintf(tablas,"Operadores sobre cadenas\n");
            break;
    }    
}

// Libera la memoria reservada para el programa
void liberarMemoria()
{
    // Recorre el arreglo de listas
    for (int i = 0; i < 10; i++)
    {
        vaciarLista(listas[i]); // Libera todos los nodos
        free(listas[i]);        // Libera el espacio de la lista
        listas[i] = NULL;       // Pierde al referencia
    }

    vaciarTokens();             // Libera el espacio de los tokens
}

// Elimina todos los nodos de una lista
void vaciarLista(LISTA* lista)                            
{
    NODO* kamikaze = lista -> head;             // Se posiciona al inicio de la lista   
    
    // Continuara mientras haya nodos en la lista
    while (kamikaze != NULL)                    
    {
        lista -> head = kamikaze -> siguiente;  // Se desplaza el inicio de la lista
        kamikaze -> siguiente = NULL;           // Se pierde la referencia a la lista
        free(kamikaze);                         // Se libera el espacio reservado
        kamikaze = lista -> head;               // Regresamos al inicio de la lista
    }
}

// Libera el espacio reservado para los tokens
void vaciarTokens()
{
    TOKEN* token_aux = tokens_L -> head;            // Nodo auxiliar que recorrera la lista

    // Se detiene al pasar todos los tokens
    while(token_aux != NULL)
    {
        tokens_L -> head = token_aux -> siguiente;  // Desplazamos el incio de la lista
        token_aux -> siguiente = NULL;              // Perdemos la referenica del token
        free(token_aux);                            // Liberamos el espacio del token
        token_aux = tokens_L -> head;               // Se recorre el nodo auxiliar
    }

    // Delvemos la lista al estado inicial
    tokens_L -> head = NULL;
    tokens_L -> tail = NULL;
}

// Funcion que transforma la secuencia de tokens en la cadena de atomicas
char* generarAtomicas()
{
    TOKEN* auxiliar = tokens_L -> head;                                         // Nodo para recorrer la lista de tokens
    char* cadena = NULL;                                                        // Guarda la cadena de atomicas
    char atomo = 'a';                                                                 // Auxiliar para agregar elementos a la cadena

    if (contador_tokens)                                                        // Comprobamos que exista al menos un token
    {   
        cadena = (char*) malloc(sizeof(char));                                  // Reservamos la memoria para el atomo
        //atomo = encontrarEquivalencia(auxiliar -> clase, auxiliar -> valor);    // Encontramos la equivalencia del token    
        cadena[contador_atomos] = atomo;                                        // Se agrega el elemento a la cadena
        contador_atomos++;                                                      // Se inicia el conteo de atomos
        auxiliar = auxiliar -> siguiente;                                       // Nos desplazamos al siguiente token

        while (auxiliar != NULL)                                                // Continua hasta recorrer toda la lista
        {
            cadena = (char*) realloc(cadena, sizeof(char)*(contador_atomos+2)); // Ampliamos la memoria de la cadena
            //atomo = encontrarEquivalencia(auxiliar -> clase, auxiliar -> valor);// Encontramos la equivalencia del token
            cadena[contador_atomos] = atomo;                                    // Se agrega el elemento a la cadena
            contador_atomos++;                                                  // Se contabiliza el atomo
            auxiliar = auxiliar -> siguiente;                                   // Nos desplazamos al siguiente token
        }
        
        cadena = (char*) realloc(cadena, sizeof(char)*(contador_atomos+2));     // Ampliamos la memoria de la cadena
        cadena[contador_atomos] = '~';                                          // Colocamos el fin de cadena
        contador_atomos++;                                                      // Finalizamos el conteo de atomos
        return cadena;                                                          // Devuelve el apuntador a la cadena
    }
    
    return cadena;                                                              // Se devuelve la cadena vacia
}

// Realiza el analisis sintactico descendente recursivo de la cadena de atomicas
void AnaSint()
{
    return;
}
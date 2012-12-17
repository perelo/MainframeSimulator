#include <iostream>

#include <CExc.h>
#include <nsSysteme.h> 

#include <CPU.h>

using namespace nsSysteme; 
using namespace std;

int main(int argc, char * argv []) {
    try {    
        cerr << (sizeof(int));
        CPU cpu("M",cerr,cin,cout,32,6); 
        cpu . run();
        return 0;
    }
    catch (const CExc & Exc) {
        cerr << Exc << endl;
        return errno;
    }
    catch (const exception & Exc) {
        cerr << "Exception : " << Exc.what () << endl;
        return 1;
    }
    catch (...) {
        cerr << "Exception inconnue recue dans la fonction main()" << endl;
        return 1;
    }
} // main()


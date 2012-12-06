/**
 *
 * @File : nsSysteme.cxx
 *
 *
 * @Synopsis : definition des wrappers non inline des fonctions syst,
 *		   definition des fonctions shell	
 *
**/

#include <string>
#include <unistd.h>     // getdtablesize()
#include <sys/time.h>   // fd_set
#include <fcntl.h>       // O_CREAT, open()
#include <sys/types.h>   // mode_t
#include <cstddef>       // size_t
#include <stdlib.h>     //system()

#include "CExc.h"
#include "nsSysteme.h"

using namespace std;     // string


///////////////////////////////////////////////////////////////////
//Definitions des fonctions systeme
////////////////////////////////////////////////////////////////////


int nsSysteme::Open (const char * pathname, int flags, ::mode_t mode)
    throw (CExc)
{
    int Res;
    if (!(flags & O_CREAT)) 
        throw CExc ("Open()",string (" fichier :") + pathname +
                       ". Un parametre de trop");
    if (-1 == (Res = ::open (pathname, flags, mode)))
        throw CExc ("open() ", string (" fichier :") + pathname);

    return Res;

} // Open()

int nsSysteme::Open (const char * pathname, int flags)
    throw (CExc)
{
    int Res;
    if (flags & O_CREAT) 
        throw CExc ("Open()",string (" fichier :") + pathname +
                    ". Il manque un parametre");
    if (-1 == (Res = ::open (pathname, flags)))
        throw CExc ("open() ", string (" fichier :") + pathname);

    return Res;

} // Open()

////////////////////////////////////////////////////////////////////////
//Definitions des fonctions pour les signaux
////////////////////////////////////////////////////////////////////////

sighandler_t nsSysteme::Signal (int NumSig,
                                           sighandler_t NewHandler) 
    throw (CExc) 
{ 
    struct sigaction Action, OldAction; 
    Action.sa_handler = NewHandler; 
    Action.sa_flags   = 0; 
    ::sigemptyset (& Action.sa_mask); 
    if (::sigaction (NumSig, & Action, & OldAction)) 
        throw CExc ("Signal()",""); 

    return OldAction.sa_handler; 

} // Signal() 





///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
//Definitions des mini-fonctions shell
///////////////////////////////////////////////////////////////////////

void nsFctShell::FileCopy (const char * const Destination,
                       const char * const Source, const size_t NbBytes, 
		       const bool         syn /*= false*/)
                                             throw (nsSysteme::CExc)
{
    const int fdSource = nsSysteme::Open (Source, O_RDONLY);
    const int fdDest   = nsSysteme::Open (Destination, 
                               O_CREAT | O_TRUNC | O_WRONLY
			       | (syn ? O_SYNC : 0),
                               0700);


    char Tampon [NbBytes];

    for (; nsSysteme::Write (fdDest, Tampon, nsSysteme::Read (fdSource, Tampon, NbBytes)); );

    nsSysteme::Close (fdSource);
    nsSysteme::Close (fdDest);

} // FileCopy()



void nsFctShell::Destroy (const char * const File)  throw (nsSysteme::CExc){

        string Commande ("ls -l ");
        Commande += File;

        char c;
        cout << "Avant unlink() : " << flush;
        system(Commande.c_str());
        nsSysteme::Unlink (File);
        cout << "Apres unlink() : " << flush;
        system(Commande.c_str());
        cout << "Appuyez sur return pour continuer";
        cin.get (c);

}  //  Destroy()

 
  
void nsFctShell::DerouterSignaux(sighandler_t Traitant) throw(nsSysteme::CExc) {
 	
      struct sigaction Action,OldAction;
      nsSysteme::TabSigHandlers TabAncTraitant; //
	
    	Action.sa_flags   = 0;
    	Action.sa_handler = Traitant;
    	::sigemptyset (& Action.sa_mask);

    	for (int i =1 ; i<nsSysteme::CstSigMax; ++i ){
        	if ((SIGKILL != i)&& (SIGSTOP != i) && (SIGCONT!=i)) {

       		try { 
				nsSysteme::Sigaction (i, & Action, &OldAction); 
			}

        		catch (const nsSysteme::CExc & ) {  
            		// Si sigaction est interrompue par 
	    			// l'arrivee des signaux errno == EINTR 
            		// il faut essayer de derouter a nouveau le signal
	    			if (EINTR==errno) {
					cout << "ressaye " << i << "\n";
            				continue;
				}
	    			else 	throw;
    
        		}
		}
		TabAncTraitant[i] = OldAction;

	}

}//DerouterSignaux




void nsFctShell::TestFdOuverts (ostream & os /* = cout */) throw (nsSysteme::CExc) 
{ 
    const int CstTaille = ::getdtablesize (); 

    os << "\nListe des descripteurs des fichiers ouverts :" << endl; 
    for (int i = 0; i < CstTaille; ++i) 
    { 
        errno=0;
        try { nsSysteme::Lseek (i, 0, SEEK_CUR); } 

        catch (const nsSysteme::CExc & Exc) 
        { 
            if (EBADF  == errno) continue; 

            // la fonction lseek() ne peut etre utilise sur un
            //   "fichier" pipe, fifo, terminal ou socket, entranant 
            //   errno == ESPIPE ==> mais le "fichier" est bien ouvert !

            if (ESPIPE != errno) throw; 
        } 
        os <<"processus  "<<::getpid()<< ";  fichier ouvert  "<<i<<endl; 
    } 

} // TestFdOuverts() 



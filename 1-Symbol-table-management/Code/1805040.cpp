#include<iostream>
#include<string>
#include<sstream>
#include<fstream>
using namespace std;

// hash function
static unsigned long sdbm(string str) {
    unsigned long hashValue = 0;
    int c;
    for(int i=0; i<str.length(); i++) {
        char c = str[i];
        hashValue = c + (hashValue << 6) + (hashValue << 16) - hashValue;
    }
    return hashValue;
}


class SymbolInfo {
    string name;
    string type;

    SymbolInfo *next;

public:
    SymbolInfo(string name, string type) {
        this->name = name;
        this->type = type;
        this->next = nullptr;
    }

    ~SymbolInfo() { delete next; }

    void setName(string name) { this->name = name; }
    void setType(string type) { this->type = type; }
    void setNext(SymbolInfo *p) { this->next = p; }
    string getName() { return name; }
    string getType() { return type; }
    SymbolInfo *getNext() { return next; }
};

class ScopeTable {

    SymbolInfo **scopeTable;
    ScopeTable *parentScopeTable;
    string id;
    int totalBuckets;

    int numOfChildren;

public:

    ScopeTable(int n) {
        totalBuckets = n;
        scopeTable = new SymbolInfo*[totalBuckets];
        numOfChildren = 0;
        parentScopeTable = nullptr;
        id = "1";

        for(int i=0; i<n; i++)  scopeTable[i] = nullptr;
    }

    ~ScopeTable() {
        // destructor
        for(int i=0; i<totalBuckets; i++)   delete scopeTable[i];
        delete []scopeTable;
    }

    void setParentScopeTable(ScopeTable *p) { parentScopeTable = p; }
    ScopeTable *getParentScopeTable() { return parentScopeTable; }

    void setID(string s) { id = s; }
    string getID() { return id; }

    void setNumOfChildren(int n) { numOfChildren = n;}
    int getNumOfChildren() { return numOfChildren; }

    bool insert(SymbolInfo *p) {
        int index = sdbm(p->getName()) % totalBuckets;
        int secIdx = 0;
        if(scopeTable[index] == nullptr) {
            scopeTable[index] = p;
            cout << "Inserted in ScopeTable# " << this->id << " at position " << index << ", " << secIdx << endl;
        }
        else {
            SymbolInfo *currentSymbol = scopeTable[index];
            while(currentSymbol->getNext() != nullptr) {
                currentSymbol = currentSymbol->getNext();
                secIdx++;
            }
            currentSymbol->setNext(p);
            cout << "Inserted in ScopeTable# " << this->id << " at position " << index << ", " << secIdx + 1 << endl;
        }


        return true;
    }

    SymbolInfo *lookUp(string name) {
        int index = sdbm(name) % totalBuckets;
        if(scopeTable[index] == nullptr) { return nullptr;}
        else if(scopeTable[index]->getName() == name)    {
            cout << name << " found in ScopeTable# " << this->id << " at position " << index << ", 0" << endl;
            return scopeTable[index];
        }
        else {
            int secIdx = -1;
            SymbolInfo *currentSymbol = scopeTable[index];
            SymbolInfo *found = nullptr;
            while(currentSymbol->getNext() != nullptr) {
                if(currentSymbol->getName() == name)   {
                    found = currentSymbol;
                    break;
                }
                else {
                    currentSymbol = currentSymbol->getNext();
                    secIdx++;
                }
            }
            if(found == nullptr)    {
                //cout << "Not found" << endl;
                return nullptr;
            }
            else {
                cout << name << " found in ScopeTable# " << this->id << " at position " << index << ", " << secIdx + 1 << endl;
                return found;
            }
        }
    }

    bool deleteSymbol(string name) {
        // delete
        int index = sdbm(name) % totalBuckets;
        if(scopeTable[index] == nullptr) {
            cout << name << " not found" << endl;
            return false;
        }
        else if(scopeTable[index]->getName() == name)    {
            // found at the head of the chain
            SymbolInfo *deleted = scopeTable[index];
            scopeTable[index] = deleted->getNext();
            delete deleted;
            cout << name << " deleted from current scope" << endl;
            return true;
        }
        else {
            // may be in the middle
            SymbolInfo *currentSymbol = scopeTable[index];
            while(currentSymbol->getNext() != nullptr && currentSymbol->getNext()->getName() != name) {
                currentSymbol = currentSymbol->getNext();
            }
            if(currentSymbol->getNext() == nullptr) {
                cout << name << " not found" << endl;
                return false;
            }
            else {
                SymbolInfo *deleted = currentSymbol->getNext();
                currentSymbol->setNext(deleted->getNext());
                cout << name << " deleted from current scope" << endl;
                delete deleted;
                return true;
            }
        }
    }

    void print() {
        cout << "ScopeTable# " << this->id << endl;
        for(int i=0; i<this->totalBuckets; i++) {
            cout << i << "--> ";
            SymbolInfo *currentSymbol = scopeTable[i];
            while(currentSymbol != nullptr) {
                cout << "<" << currentSymbol->getName() << ":" << currentSymbol->getType() << ">";
                currentSymbol = currentSymbol->getNext();
            }
            cout << endl;
        }
    }


};



class SymbolTable {

    ScopeTable *currentScopeTable;
    int numberOfBuckets;

public:

    SymbolTable(int n) {
        currentScopeTable = new ScopeTable(n);
        numberOfBuckets = n;
    }

    ~SymbolTable() { delete currentScopeTable; }

    void enterScope() {
        ScopeTable *newScopeTable = new ScopeTable(numberOfBuckets);
        currentScopeTable->setNumOfChildren(currentScopeTable->getNumOfChildren()+1);
        ScopeTable *parent = currentScopeTable;
        currentScopeTable = newScopeTable;
        currentScopeTable->setParentScopeTable(parent);
        currentScopeTable->setID(parent->getID() + "." + to_string(parent->getNumOfChildren()));

        cout << "New scope table with id " << currentScopeTable->getID() << " created" << endl;
    }

    void exitScope() {

        if(currentScopeTable->getParentScopeTable() == nullptr) cout << "Cannot delete main scope" << endl;

        else {
           ScopeTable *tempScopeTable = currentScopeTable;
        currentScopeTable = currentScopeTable->getParentScopeTable();
        cout << "ScopeTable with id " << tempScopeTable->getID() << " removed" << endl;
        delete tempScopeTable;
        }
    }

    bool insert(SymbolInfo *p) {
        SymbolInfo *temp = currentScopeTable->lookUp(p->getName());
        if(temp == nullptr)    return currentScopeTable->insert(p);
        else {
            cout << "<" << p->getName() << ":" << p->getType() << "> already exists in current ScopeTable" << endl;
            return false;
        }
    }

    bool remove(string name) {
        return currentScopeTable->deleteSymbol(name);
    }

    SymbolInfo *lookUp(string name) {
        SymbolInfo *temp = currentScopeTable->lookUp(name);
        ScopeTable *tempScopeTable = currentScopeTable;
        while(temp == nullptr && tempScopeTable != nullptr) {
            tempScopeTable = tempScopeTable->getParentScopeTable();
            if(tempScopeTable != nullptr) temp = tempScopeTable->lookUp(name);
        }


        if(tempScopeTable == nullptr) cout << name << " not found" << endl;
        else return temp;
    }

    void printCurrentScopeTable() { currentScopeTable->print();}

    void printAllScopeTable() {
        ScopeTable *tempScopeTable = currentScopeTable;

        while(tempScopeTable != nullptr) {
            tempScopeTable->print();
            tempScopeTable = tempScopeTable->getParentScopeTable();
        }
    }

};


int main() {

    string line;

	ifstream inputFile("input.txt");
	bool isFirstLine = true;
	int totalBuckets;
	SymbolTable *symbolTable;

	while(getline(inputFile, line)) {
	    istringstream input(line);
	    if(isFirstLine){
	    	isFirstLine=false;
	    	input >> totalBuckets;
	    	symbolTable = new SymbolTable(totalBuckets);
		}
		else{
			string functionality, firstInput, secondInput;
		    input >> functionality;
		    if(functionality == "I"){
		    	input >> firstInput >> secondInput;
		    	symbolTable->insert(new SymbolInfo(firstInput, secondInput));
			}
			else if(functionality == "L"){
		    	input >> firstInput;
		    	symbolTable->lookUp(firstInput);
			}
			else if(functionality == "D") {
                input >> firstInput;
                symbolTable->remove(firstInput);
			}
			else if(functionality == "P") {
                input >> firstInput;
                if(firstInput == "A")   symbolTable->printAllScopeTable();
                else if(firstInput == "C") symbolTable->printCurrentScopeTable();
			}
			else if(functionality == "S")   symbolTable->enterScope();
            else if(functionality == "E")   symbolTable->exitScope();
            else cout << "Invalid input" << endl;

		}
	}



    return 0;
}
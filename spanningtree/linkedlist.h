#ifndef _LINKEDLIST_H_
#define _LINKEDLIST_H_

typedef struct llnode llnode_t;
struct llnode {
	void *data;
	llnode_t *next;
	llnode_t *head;
	llnode_t *tail;
};

void lladd(llnode_t **list, void *data);
void llmerge(llnode_t **x, llnode_t **y);
void printlist(llnode_t *list, void (*func)(void *));

#endif

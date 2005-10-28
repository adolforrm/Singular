LIB "tst.lib";
tst_init();


//======================  Exercise 5.1 =============================
proc min_generating_set (matrix P,S)
"USAGE:  min_generating_set(P,S);   P,S matrix
ASSUME: The entries of P,S are homogeneous and ordered by ascending 
        degrees. The first entry of S equals 1. (As satisfied by 
        the first two output matrices of invariant_ring(G).)
RETURN: ideal
NOTE:   The given generators for the output ideal form a minimal 
        generating set for the ring generated by the entries of 
        P,S. The generators are homogeneous and ordered by 
        descending degrees.
"
{
  if (defined(flatten)==0) { LIB "matrix.lib"; }
  ideal I1,I2 = flatten(P),flatten(S); 
  int i1,i2 = size(I1),size(I2);
  // We order the generators by descending degrees
  // (the first generator 1 of I2 is omitted):
  int i,j,s = i1,i2,i1+i2-1;
  ideal I;
  for (int k=1; k<=s; k++)
  { 
    if (i==0) { I[k]=I2[j]; j--; } 
    else
    { 
      if (j==0) { I[k]=I1[i]; i--; } 
      else 
      {
        if (deg(I1[i])>deg(I2[j])) { I[k]=I1[i]; i--; }
        else { I[k]=I2[j]; j--; }
      }
    }
  } 
  intvec deg_I = deg(I[1..s]);
  int n = nvars(basering);
  def BR = basering;

  // Create a new ring with elimination order:
  //---------------------------------------------------------------
  // ****    this part uses the command ringlist which is      ****
  // ****     only available in SINGULAR-3-0-0 or newer        ****
  //---------------------------------------------------------------
  list rData = ringlist(BR);
  intvec wDp;
  for (k=1; k<=n; k++) { 
    rData[2][k] ="x("+string(k)+ ")"; 
    wDp[k]=1;
  }
  for (k=1; k<=s; k++) { rData[2][n+k] ="y("+string(k)+ ")"; } 
  rData[3][1] = list("dp",wDp);
  rData[3][2] = list("wp",deg_I);
  def R_aux = ring(rData);
  setring R_aux;
  //---------------------------------------------------------------

  ideal J;
  map phi = BR, x(1..n);
  ideal I = phi(I);
  for (k=1; k<=s; k++) { J[k] = y(k)-I[k]; } 
  option(redSB);
  J = std(J);

  // Remove all generators that are depending on some x(i) from J: 
  int s_J = size(J);
  for (k=1; k<=s_J; k++) { if (J[k]>=x(n)) {J[k]=0;} }

  // The monomial order on K[y] is chosen such that linear leading 
  // terms in J are in 1-1 correspondence to superfluous generators
  // in I :
  ideal J_1jet = std(jet(lead(J),1));
  intvec to_remove; 
  i=1;
  for (k=1; k<=s; k++)
  { 
    if (reduce(y(k),J_1jet)==0){ to_remove[i]=k; i++; }
  }
  setring BR;
  if (to_remove == 0) { return(ideal(I)); }
  for (i=1; i<=size(to_remove); i++)
  { 
    I[to_remove[i]] = 0;
  } 
  I = simplify(I,2);
  return(I);
}

ring R1 = 0, (x,y), dp;
matrix P[1][3] = x2+y2, x2-y2, x3-y3;
matrix S[1][5] = 1, x-y, x3-xy2, x4-y4, xy3+y4;
min_generating_set(P,S);
//-> _[1]=x2-y2
//-> _[2]=x2+y2
//-> _[3]=x-y

ring R = 2, x(1..4), dp;
matrix A[4][4];
A[1,4]=1; A[2,1]=1; A[3,2]=1; A[4,3]=1;
if (not(defined(invariant_ring))){ LIB "finvar.lib"; }
matrix P,S = invariant_ring(A);
ideal MGS = min_generating_set(P,S);
deg(MGS[1]);
//-> 5


kill R,R1;
//======================  Exercise 5.2 =============================
proc is_unit (poly f)
"USAGE:  is_unit(f);   f poly
RETURN: int;  1 if f is a unit in the active ring,
              0 otherwise.
"
{
  return(leadmonom(f)==1);
}

ring R = 0, (x,y), dp;
poly f = 3+x;
is_unit(f);
ring R1 = 0, (x,y), ds;
is_unit(imap(R,f));
ring R2 = 0, (x,y), (ds(1),dp);
is_unit(imap(R,f));
ring R3 = 0, (x,y), (dp(1),ds);
is_unit(imap(R,f));

proc invert_unit (poly u, int d)
"USAGE:   invert_unit(u,d);   u poly, d int
RETURN:  poly; 
NOTE:    If u is a unit in the active ring, the output polynomial 
         is the power series expansion of the inverse of u up to 
         order d. Otherwise, the zero polynomial is returned.
"
{
  if (is_unit(u)==0) { return(poly(0)); }
  poly u_0 = jet(u,0);
  u = jet(1-u/u_0,d);
  poly u_1 = u;
  poly inv = 1 + u_1;
  for (int i=2; i<=d; i++)
  { 
    u_1 = jet(u_1*u,d);
    inv = inv + u_1;  
  }
  return(inv/u_0);
}

setring R1;
poly inv_f = invert_unit(imap(R,f),100);
lead(imap(R,f)*inv_f - 1);
//-> 1/1546132562196033993109383389296863818106322566003x101


kill R,R1,R2,R3;
//======================  Exercise 5.3 =============================
if (not(defined(minAssGTZ))){ LIB "primdec.lib"; }
ring R = 0, (x,y,z), dp;
poly f = ((x4+y4-z4)^4-x2y5z9)*(x4+y4-z4);
ideal Slocf = f,jacob(f);
list SLoc = minAssGTZ(Slocf);
SLoc;
//-> [1]:
//->    _[1]=x4+y4
//->    _[2]=z
//-> [2]:
//->    _[1]=y-z
//->    _[2]=x
//-> [3]:
//->    _[1]=y+z
//->    _[2]=x
//-> [4]:
//->    _[1]=y2+z2
//->    _[2]=x
//-> [5]:
//->    _[1]=x2+z2
//->    _[2]=y
//-> [6]:
//->    _[1]=y
//->    _[2]=x+z
//-> [7]:
//->    _[1]=y
//->    _[2]=x-z

if (not(defined(hnexpansion))){ LIB "hnoether.lib"; }
ring R_loc1 = 0, (u,v), ds;
map phi = R,u,v-1,1;
poly f = phi(f);
def L1 = hnexpansion(f);
def HNE_ring1 = L1[1];
setring HNE_ring1;
list INV = invariants(hne);
// Number of branches:
size(INV)-1;              
//-> 3
// Intersection Multiplicities of the branches:
print(INV[size(INV)][2]);
//->     0     1     1
//->     1     0     2
//->     1     2     0

for (int i=1; i<size(INV); i++)
{ 
 if (INV[i][5]==0){ print("branch No."+string(i)+" is smooth");}
}

ring R_loc2 = (0,a), (u,v), ds;
minpoly = a2+1;   
map phi = R,u,v-a,1;
poly f = phi(f);
def L2 = hnexpansion(f);
def HNE_ring2 = L2[1];
setring HNE_ring2;
displayInvariants(hne);

ring R_loc3 = (0,a), (u,v), ds;
minpoly = a4+1;
map phi = R,1,v-a,u;
poly f = phi(f);
def L3 = hnexpansion(f);
displayInvariants(L3);


kill R,R_loc1,R_loc2,R_loc3,HNE_ring1,HNE_ring2,L1,L2,i,INV; 
//======================  Exercise 5.4 =============================
ring R = 0, (x,y,z), dp;
poly f = 3y3-3xy2-2xy3+x2y3+x3;
poly C = homog(f,z);
ideal I = jacob(C);
I = std(I);
if(not(defined(primdecGTZ))){ LIB "primdec.lib"; }
list SLoc = primdecGTZ(I); 
SLoc;
factorize(jet(f,3));
//-> [1]:
//->    _[1]=1
//->    _[2]=x3-3xy2+3y3
//-> [2]:
//->    1,1

ideal Adj_S = 1;
for (int k=1; k<=3; k++)
{
  Adj_S = intersect(Adj_S,SLoc[k][2]);
}
Adj_S = intersect(Adj_S,SLoc[k][2]^2);
ideal Adj_LS_3 = jet(std(Adj_S),3);
Adj_LS_3 = simplify(Adj_LS_3,6);  Adj_LS_3;

if (not(defined(randomid))){ LIB "random.lib"; }
def f(1),f(2) = randomid(Adj_LS_3,2,10);
ideal I(1) = f(1),C;
ideal I(2) = f(2),C;
ideal B(1) = sat(I(1),I)[1];
ideal B(2) = sat(I(2),I)[1];

Adj_S = intersect(Adj_S,B(1),B(2));
option(redSB);
ideal L' = jet(std(Adj_S),4);
L' = simplify(L',6);
poly f' =  randomid(L',1,10)[1];
ideal I' = f',C;
ideal B(3) = sat(I',L')[1];

ideal L'' = jet(std(intersect(Adj_LS_3,B(3))),3);
L'' = simplify(L'',6);  L'';
poly f''(1),f''(2) = L'';

ring R_t = (0,t), (x,y,z), dp;
poly f'' = imap(R,f''(1)) + t*imap(R,f''(2));
ideal I_t = f'', imap(R,C);
I_t = std(I_t);
ideal L'' = imap(R,L'');
I_t = sat(I_t,L'')[1];
I_t = std(subst(I_t,z,1));
def phi_x = reduce(x,I_t);  phi_x;
def phi_y = reduce(y,I_t);  phi_y;

map testmap = R, phi_x, phi_y, 1;
testmap(C);
//-> 0
ring S = 0, (t,x,y), dp;
ideal I_t = imap(R_t,I_t);
eliminate(I_t,t);
//-> _[1]=x2y3-2xy3+x3-3xy2+3y3

tst_status(1);$


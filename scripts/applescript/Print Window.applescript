FasdUAS 1.101.10   ��   ��    k             l      ��  ��   ��
Copyright � 2003 Apple Computer, Inc.

You may incorporate this Apple sample code into your program(s) without
restriction.  This Apple sample code has been provided "AS IS" and the
responsibility for its operation is yours.  You are not permitted to
redistribute this Apple sample code as "Apple sample code" after having
made changes.  If you're going to redistribute the code, we require
that you make it clear that the code was descended from Apple sample
code, but that you've made changes.
     � 	 	� 
 C o p y r i g h t   �   2 0 0 3   A p p l e   C o m p u t e r ,   I n c . 
 
 Y o u   m a y   i n c o r p o r a t e   t h i s   A p p l e   s a m p l e   c o d e   i n t o   y o u r   p r o g r a m ( s )   w i t h o u t 
 r e s t r i c t i o n .     T h i s   A p p l e   s a m p l e   c o d e   h a s   b e e n   p r o v i d e d   " A S   I S "   a n d   t h e 
 r e s p o n s i b i l i t y   f o r   i t s   o p e r a t i o n   i s   y o u r s .     Y o u   a r e   n o t   p e r m i t t e d   t o 
 r e d i s t r i b u t e   t h i s   A p p l e   s a m p l e   c o d e   a s   " A p p l e   s a m p l e   c o d e "   a f t e r   h a v i n g 
 m a d e   c h a n g e s .     I f   y o u ' r e   g o i n g   t o   r e d i s t r i b u t e   t h e   c o d e ,   w e   r e q u i r e 
 t h a t   y o u   m a k e   i t   c l e a r   t h a t   t h e   c o d e   w a s   d e s c e n d e d   f r o m   A p p l e   s a m p l e 
 c o d e ,   b u t   t h a t   y o u ' v e   m a d e   c h a n g e s . 
   
  
 l     ��������  ��  ��        l     ��������  ��  ��        i         I     �� ��
�� .aevtoappnull  �   � ****  J      ����  ��    k     S       O        r        c    	    l    ����  1    ��
�� 
sele��  ��    m    ��
�� 
alst  o      ���� "0 finderselection FinderSelection  m       �                                                                                  MACS   alis    b  Leopard                    �5qH+     �
Finder.app                                                       s��01�        ����  	                CoreServices    �5v�      �0�       �   Q   P  .Leopard:System:Library:CoreServices:Finder.app   
 F i n d e r . a p p    L e o p a r d  &System/Library/CoreServices/Finder.app  / ��        l   ��������  ��  ��       !   r     " # " o    ���� "0 finderselection FinderSelection # o      ���� 0 fs FS !  $ % $ l   �� & '��   & < 6Ideally, this list could be passed to the open handler    ' � ( ( l I d e a l l y ,   t h i s   l i s t   c o u l d   b e   p a s s e d   t o   t h e   o p e n   h a n d l e r %  ) * ) l   ��������  ��  ��   *  + , + l    - . / - r     0 1 0 n     2 3 2 m    ��
�� 
nmbr 3 o    ���� 0 fs FS 1 o      ����  0 selectioncount SelectionCount .   count	    / � 4 4    c o u n t 	 ,  5 6 5 Z    M 7 8 9 : 7 =    ; < ; o    ����  0 selectioncount SelectionCount < m    ����   8 r    $ = > = I    "�������� "0 userpicksfolder userPicksFolder��  ��   > o      ���� 0 fs FS 9  ? @ ? =  ' * A B A l  ' ( C���� C o   ' (����  0 selectioncount SelectionCount��  ��   B m   ( )����  @  D�� D k   - I E E  F G F r   - 4 H I H I  - 2�� J��
�� .earsffdralis        afdr J  f   - .��   I o      ���� 0 mypath MyPath G  K�� K Z   5 I L M���� L =  5 ; N O N o   5 6���� 0 mypath MyPath O n   6 : P Q P 4   7 :�� R
�� 
cobj R m   8 9����  Q o   6 7���� 0 fs FS M k   > E S S  T U T l  > >�� V W��   V 0 *If I'm a droplet then I was double-clicked    W � X X T I f   I ' m   a   d r o p l e t   t h e n   I   w a s   d o u b l e - c l i c k e d U  Y�� Y r   > E Z [ Z I   > C�������� "0 userpicksfolder userPicksFolder��  ��   [ o      ���� 0 fs FS��  ��  ��  ��  ��   : l  L L�� \ ]��   \ &  I'm not a double-clicked droplet    ] � ^ ^ @ I ' m   n o t   a   d o u b l e - c l i c k e d   d r o p l e t 6  _ ` _ l  N N��������  ��  ��   `  a�� a I  N S�� b��
�� .aevtodocnull  �    alis b o   N O���� 0 fs FS��  ��     c d c l     ��������  ��  ��   d  e f e i     g h g I      �������� "0 userpicksfolder userPicksFolder��  ��   h k      i i  j k j r      l m l J     ����   m o      ���� 0 these_items   k  n�� n r     o p o c     q r q l    s���� s I   ���� t
�� .sysostflalis    ��� null��   t �� u��
�� 
prmp u m     v v � w w b S e l e c t   a   f o l d e r   w h o s e   c o n t e n t s   y o u   w i s h   t o   p r i n t :��  ��  ��   r m    ��
�� 
list p o      ���� 0 these_items  ��   f  x y x l     ��������  ��  ��   y  z { z j    
�� |�� 0 
pshortpath 
pShortPath | m    	 } } � ~ ~   {   �  l     ��������  ��  ��   �  � � � i     � � � I     �� ���
�� .aevtodocnull  �    alis � o      ���� 0 these_items  ��   � k     R � �  � � � r      � � � J     ����   � l      ����� � o      ���� 0 	item_info  ��  ��   �  ��� � Y    R ��� � ��� � k    M � �  � � � r     � � � l    ����� � n     � � � 4    �� �
�� 
cobj � o    ���� 0 i   � o    ���� 0 these_items  ��  ��   � o      ���� 0 	this_item   �  � � � r    ! � � � I   �� ���
�� .sysonfo4asfe       **** � o    ���� 0 	this_item  ��   � l      ����� � o      ���� 0 	item_info  ��  ��   �  ��� � Z   " M � ����� � =  " ' � � � n   " % � � � 1   # %��
�� 
asdr � l  " # ����� � o   " #���� 0 	item_info  ��  ��   � m   % &��
�� boovtrue � l  * I � � � � k   * I � �  � � � r   * 6 � � � l  * 0 ����� � c   * 0 � � � n   * . � � � 4   + .�� �
�� 
cobj � o   , -���� 0 i   � o   * +���� 0 these_items   � m   . /��
�� 
TEXT��  ��   � o      ���� 0 
pshortpath 
pShortPath �  � � � r   7 B � � � c   7 @ � � � n   7 > � � � 1   < >��
�� 
psxp � o   7 <���� 0 
pshortpath 
pShortPath � m   > ?��
�� 
TEXT � o      ���� $0 theposixfilepath thePOSIXFilePath �  �� � I   C I�~ ��}�~ 0 processfolder processFolder �  ��| � o   D E�{�{ $0 theposixfilepath thePOSIXFilePath�|  �}  �   �  if the item is a folder    � � � � . i f   t h e   i t e m   i s   a   f o l d e r��  ��  ��  �� 0 i   � m    	�z�z  � l  	  ��y�x � I  	 �w ��v
�w .corecnte****       **** � o   	 
�u�u 0 these_items  �v  �y  �x  ��  ��   �  � � � l     �t�s�r�t  �s  �r   �  � � � l     �q�p�o�q  �p  �o   �  � � � i     � � � I      �n ��m�n 0 processfolder processFolder �  ��l � o      �k�k 0 	thefolder 	theFolder�l  �m   � k     l � �  � � � r      � � � n     � � � 1    �j
�j 
txdl � 1     �i
�i 
ascr � o      �h�h 0 	olddelims 	OldDelims �  � � � r     � � � m     � � � � �  / � n      � � � 1    
�g
�g 
txdl � 1    �f
�f 
ascr �  � � � r     � � � n     � � � 2   �e
�e 
citm � o    �d�d 0 	thefolder 	theFolder � o      �c�c 0 newtextlist newTextList �  � � � r     � � � l    ��b�a � I   �` ��_
�` .corecnte****       **** � o    �^�^ 0 newtextlist newTextList�_  �b  �a   � o      �]�] 0 x   �  � � � r    + � � � c    ) � � � n    ' � � � 7   '�\ � �
�\ 
cobj � m    !�[�[  � l  " & ��Z�Y � \   " & � � � o   # $�X�X 0 x   � m   $ %�W�W �Z  �Y   � o    �V�V 0 newtextlist newTextList � m   ' (�U
�U 
TEXT � o      �T�T 0 printedpath printedPath �  � � � r   , 1 � � � o   , -�S�S 0 	olddelims 	OldDelims � n      � � � 1   . 0�R
�R 
txdl � 1   - .�Q
�Q 
ascr �  � � � l  2 2�P�O�N�P  �O  �N   �  � � � l  2 2�M�L�K�M  �L  �K   �  ��J � Q   2 l   k   5 H  r   5 B l  5 @�I�H c   5 @	
	 b   5 > b   5 < b   5 : b   5 8 m   5 6 �  (   e c h o   o   6 7�G�G 0 printedpath printedPath m   8 9 �    & &   l s   - l     " o   : ;�F�F 0 	thefolder 	theFolder m   < = �  "     )   |   l p r  
 m   > ?�E
�E 
TEXT�I  �H   o      �D�D  0 theshellscript theShellScript �C I  C H�B�A
�B .sysoexecTEXT���     TEXT o   C D�@�@  0 theshellscript theShellScript�A  �C   R      �?
�? .ascrerr ****      � **** o      �>�> 0 errmsg ErrMsg �=�<
�= 
errn o      �;�; 0 errnmbr ErrNmbr�<   O   P l I  T k�: !
�: .sysodlogaskr        TEXT  b   T Y"#" b   T W$%$ o   T U�9�9 0 errmsg ErrMsg% m   U V&& �''  
 E r r o r :  # o   W X�8�8 0 errnmbr ErrNmbr! �7()
�7 
btns( J   Z _** +�6+ m   Z ],, �--  O K�6  ) �5.�4
�5 
disp. m   b e�3
�3 stic   �4   m   P Q//�                                                                                  MACS   alis    b  Leopard                    �5qH+     �
Finder.app                                                       s��01�        ����  	                CoreServices    �5v�      �0�       �   Q   P  .Leopard:System:Library:CoreServices:Finder.app   
 F i n d e r . a p p    L e o p a r d  &System/Library/CoreServices/Finder.app  / ��  �J   � 010 l     �2�1�0�2  �1  �0  1 232 l     �/�.�-�/  �.  �-  3 4�,4 l     �+�*�)�+  �*  �)  �,       �(56789:;;�'<�&�(  5 
�%�$�#�"�!� ����
�% .aevtoappnull  �   � ****�$ "0 userpicksfolder userPicksFolder�# 0 
pshortpath 
pShortPath
�" .aevtodocnull  �    alis�! 0 processfolder processFolder�  "0 finderselection FinderSelection� 0 fs FS�  0 selectioncount SelectionCount� 0 mypath MyPath�  6 � ��=>�
� .aevtoappnull  �   � ****�  �  =  >  �����������
� 
sele
� 
alst� "0 finderselection FinderSelection� 0 fs FS
� 
nmbr�  0 selectioncount SelectionCount� "0 userpicksfolder userPicksFolder
� .earsffdralis        afdr� 0 mypath MyPath
� 
cobj
� .aevtodocnull  �    alis� T� 	*�,�&E�UO�E�O��,E�O�j  *j+ E�Y (�k  !)j E�O���k/  *j+ E�Y hY hO�j 7 � h��
?@�	� "0 userpicksfolder userPicksFolder�  �
  ? �� 0 these_items  @ � v��
� 
prmp
� .sysostflalis    ��� null
� 
list�	 jvE�O*��l �&E�8 �AA f L e o p a r d : U s e r s : p e n g t a o : i P h o n e 1 , 1 _ 1 . 0 . 2 _ 1 C 2 8 _ R e s t o r e :9 � ���BC�
� .aevtodocnull  �    alis� 0 these_items  �  B � ���������  0 these_items  �� 0 	item_info  �� 0 i  �� 0 	this_item  �� $0 theposixfilepath thePOSIXFilePathC ��������������
�� .corecnte****       ****
�� 
cobj
�� .sysonfo4asfe       ****
�� 
asdr
�� 
TEXT
�� 
psxp�� 0 processfolder processFolder� SjvE�O Lk�j  kh ��/E�O�j E�O��,e  $��/�&Ec  Ob  �,�&E�O*�k+ Y h[OY��: �� �����DE���� 0 processfolder processFolder�� ��F�� F  ���� 0 	thefolder 	theFolder��  D ������������������ 0 	thefolder 	theFolder�� 0 	olddelims 	OldDelims�� 0 newtextlist newTextList�� 0 x  �� 0 printedpath printedPath��  0 theshellscript theShellScript�� 0 errmsg ErrMsg�� 0 errnmbr ErrNmbrE ���� �������������G/&��,��������
�� 
ascr
�� 
txdl
�� 
citm
�� .corecnte****       ****
�� 
cobj
�� 
TEXT
�� .sysoexecTEXT���     TEXT�� 0 errmsg ErrMsgG ������
�� 
errn�� 0 errnmbr ErrNmbr��  
�� 
btns
�� 
disp
�� stic   �� 
�� .sysodlogaskr        TEXT�� m��,E�O���,FO��-E�O�j E�O�[�\[Zk\Z�k2�&E�O���,FO �%�%�%�%�&E�O�j 
W #X  � ��%�%�a kva a a  U; ��H�� H  II�alis    �  Leopard                    �5qH+   ;AiPhone1,1_1.0.2_1C28_Restore                                    �r�u�1        ����  	                pengtao     �5v�      �vi�     ;A  y�  2Leopard:Users:pengtao:iPhone1,1_1.0.2_1C28_Restore  :  i P h o n e 1 , 1 _ 1 . 0 . 2 _ 1 C 2 8 _ R e s t o r e    L e o p a r d  *Users/pengtao/iPhone1,1_1.0.2_1C28_Restore  /    ��  �' <�alis    �   MacHD                      �]O�H+   �`Print Window.scpt                                               �V�O�eosasToyS����  	                Scripts     �]�"      �P�     �` �\ ��* 6:� 6:� 5�� 5v8  RMacHD:Develop:Source:graphics:Printing:Tioga:PrintCenter:Scripts:Print Window.scpt  $  P r i n t   W i n d o w . s c p t    M a c H D  M/Develop/Source/graphics/Printing/Tioga/PrintCenter/Scripts/Print Window.scpt   /Volumes/MacHD��  �&  ascr  ��ޭ
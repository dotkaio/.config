FasdUAS 1.101.10   ��   ��    k             l      ��  ��    l f
 * Toggle window position between left and right halves of the screen
 *
 * (c) Modified by ChatGPT
      � 	 	 � 
   *   T o g g l e   w i n d o w   p o s i t i o n   b e t w e e n   l e f t   a n d   r i g h t   h a l v e s   o f   t h e   s c r e e n 
   * 
   *   ( c )   M o d i f i e d   b y   C h a t G P T 
     
  
 l     ��������  ��  ��        l     ��  ��      Get display size     �   "   G e t   d i s p l a y   s i z e      l     ����  O         k           r        n        1   	 ��
�� 
pbnd  n    	    m    	��
�� 
cwin  1    ��
�� 
desk  o      ���� 0 b         r     ! " ! l    #���� # n     $ % $ 4    �� &
�� 
cobj & m    ����  % o    ���� 0 b  ��  ��   " o      ���� 0 displaywidth displayWidth    '�� ' r     ( ) ( l    *���� * n     + , + 4    �� -
�� 
cobj - m    ����  , o    ���� 0 b  ��  ��   ) o      ���� 0 displayheight displayHeight��    m      . .�                                                                                  MACS  alis    2  macOS                      �ǇBD ����
Finder.app                                                     �����Ǉ        ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    m a c O S  &System/Library/CoreServices/Finder.app  / ��  ��  ��     / 0 / l     ��������  ��  ��   0  1 2 1 l     �� 3 4��   3 "  Get dock size if not hidden    4 � 5 5 8   G e t   d o c k   s i z e   i f   n o t   h i d d e n 2  6 7 6 l   : 8���� 8 Z    : 9 :�� ; 9 =   $ < = < l   " >���� > I   "�� ?��
�� .sysoexecTEXT���     TEXT ? m     @ @ � A A J d e f a u l t s   r e a d   c o m . a p p l e . d o c k   a u t o h i d e��  ��  ��   = m   " # B B � C C  0 : k   ' 4 D D  E F E r   ' 2 G H G [   ' 0 I J I l  ' . K���� K c   ' . L M L l  ' , N���� N I  ' ,�� O��
�� .sysoexecTEXT���     TEXT O m   ' ( P P � Q Q J d e f a u l t s   r e a d   c o m . a p p l e . d o c k   t i l e s i z e��  ��  ��   M m   , -��
�� 
nmbr��  ��   J m   . /����  H o      ���� 0 docksize dockSize F  R�� R l  3 3�� S T��   S ; 5 NB: size of the dock is the icon size plus 19 pixels    T � U U j   N B :   s i z e   o f   t h e   d o c k   i s   t h e   i c o n   s i z e   p l u s   1 9   p i x e l s��  ��   ; r   7 : V W V m   7 8����   W o      ���� 0 docksize dockSize��  ��   7  X Y X l     ��������  ��  ��   Y  Z [ Z l     �� \ ]��   \   Set menubar size    ] � ^ ^ "   S e t   m e n u b a r   s i z e [  _ ` _ l  ; B a���� a r   ; B b c b m   ; >����  c o      ���� 0 menubarsize menubarSize��  ��   `  d e d l     ��������  ��  ��   e  f g f l  C T h���� h r   C T i j i l  C P k���� k I  C P�� l m
�� .earsffdralis        afdr l m   C F��
�� appfegfp m �� n��
�� 
rtyp n m   I L��
�� 
utxt��  ��  ��   j o      ���� 0 curapp curApp��  ��   g  o p o l     ��������  ��  ��   p  q�� q l  U6 r���� r O   U6 s t s Q   `5 u v�� u O   c, w x w k   j+ y y  z { z l  j j�� | }��   |    Get current window bounds    } � ~ ~ 4   G e t   c u r r e n t   w i n d o w   b o u n d s {   �  r   j � � � � l  j n ����� � e   j n � � 1   j n��
�� 
pbnd��  ��   � J       � �  � � � o      ���� 
0 cur_x1   �  � � � o      ���� 
0 cur_y1   �  � � � o      ���� 
0 cur_x2   �  ��� � o      ���� 
0 cur_y2  ��   �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � ( " Set vertical bounds (full height)    � � � � D   S e t   v e r t i c a l   b o u n d s   ( f u l l   h e i g h t ) �  � � � r   � � � � � o   � ����� 0 menubarsize menubarSize � o      ���� 
0 new_y1   �  � � � r   � � � � � o   � ����� 0 displayheight displayHeight � o      ���� 
0 new_y2   �  � � � l  � ���������  ��  ��   �  � � � Z   � � � ����� � D   � � � � � o   � ����� 0 curapp curApp � m   � � � � � � �  : F i n d e r . a p p : � k   � � � �  � � � l  � ��� � ���   � + % Account for TotalFinder if installed    � � � � J   A c c o u n t   f o r   T o t a l F i n d e r   i f   i n s t a l l e d �  ��� � O   � � � � � Z   � � � ����� � l  � � ����� � I  � ��� ���
�� .coredoexnull���     obj  � m   � � � � � � � @ m a c : A p p l i c a t i o n s : T o t a l F i n d e r . a p p��  ��  ��   � r   � � � � � \   � � � � � o   � ����� 
0 new_y1   � m   � ����� , � o      ���� 
0 new_y1  ��  ��   � m   � � � ��                                                                                  MACS  alis    2  macOS                      �ǇBD ����
Finder.app                                                     �����Ǉ        ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    m a c O S  &System/Library/CoreServices/Finder.app  / ��  ��  ��  ��   �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � _ Y Determine the current horizontal placement by comparing window center with screen center    � � � � �   D e t e r m i n e   t h e   c u r r e n t   h o r i z o n t a l   p l a c e m e n t   b y   c o m p a r i n g   w i n d o w   c e n t e r   w i t h   s c r e e n   c e n t e r �  � � � r   � � � � � ^   � � � � � l  � � ����� � [   � � � � � o   � ����� 
0 cur_x1   � o   � ����� 
0 cur_x2  ��  ��   � m   � �����  � o      ���� 0 windowcenter windowCenter �  � � � r   � � � � � [   � � � � � o   � ����� 0 docksize dockSize � l  � � ����� � ^   � � � � � l  � � ����� � \   � � � � � o   � ����� 0 displaywidth displayWidth � o   � ����� 0 docksize dockSize��  ��   � m   � ��� ��  ��   � o      �~�~ 0 screencenter screenCenter �  � � � l  � ��}�|�{�}  �|  �{   �  � � � Z   � � ��z � � @   � � � � � o   � ��y�y 0 windowcenter windowCenter � o   � ��x�x 0 screencenter screenCenter � k   � � �  � � � l  � ��w � ��w   � : 4 Window is on the right, so move it to the left half    � � � � h   W i n d o w   i s   o n   t h e   r i g h t ,   s o   m o v e   i t   t o   t h e   l e f t   h a l f �  � � � r   � � � � � o   � ��v�v 0 docksize dockSize � o      �u�u 
0 new_x1   �  ��t � r   � � � � [   �  � � � o   � ��s�s 0 docksize dockSize � l  � � ��r�q � ^   � � � � � l  � � ��p�o � \   � � � � � o   � ��n�n 0 displaywidth displayWidth � o   � ��m�m 0 docksize dockSize�p  �o   � m   � ��l�l �r  �q   � o      �k�k 
0 new_x2  �t  �z   � k   � �  � � � l �j � ��j   � : 4 Window is on the left, so move it to the right half    � � � � h   W i n d o w   i s   o n   t h e   l e f t ,   s o   m o v e   i t   t o   t h e   r i g h t   h a l f �  � � � r   � � � [   � � � o  �i�i 0 docksize dockSize � l  �h�g  ^   l �f�e \   o  	�d�d 0 displaywidth displayWidth o  	
�c�c 0 docksize dockSize�f  �e   m  �b�b �h  �g   � o      �a�a 
0 new_x1   � �` r   o  �_�_ 0 displaywidth displayWidth o      �^�^ 
0 new_x2  �`   � 	
	 l �]�\�[�]  �\  �[  
  l �Z�Z     Apply the new bounds    � *   A p p l y   t h e   n e w   b o u n d s �Y r  + J  '  o  �X�X 
0 new_x1    o  �W�W 
0 new_y1    o  "�V�V 
0 new_x2   �U o  "%�T�T 
0 new_y2  �U   1  '*�S
�S 
pbnd�Y   x 4  c g�R
�R 
cwin m   e f�Q�Q  v R      �P�O�N
�P .ascrerr ****      � ****�O  �N  ��   t 4   U ]�M
�M 
capp o   Y \�L�L 0 curapp curApp��  ��  ��       "�K�J�I�H�G �F�E�D�C�B�A!"�@#�?�>�=�<�;�:�9�8�7�6�5�4�3�2�1�K    �0�/�.�-�,�+�*�)�(�'�&�%�$�#�"�!� ���������������
�0 .aevtoappnull  �   � ****�/ 0 b  �. 0 displaywidth displayWidth�- 0 displayheight displayHeight�, 0 docksize dockSize�+ 0 menubarsize menubarSize�* 0 curapp curApp�) 
0 cur_x1  �( 
0 cur_y1  �' 
0 cur_x2  �& 
0 cur_y2  �% 
0 new_y1  �$ 
0 new_y2  �# 0 windowcenter windowCenter�" 0 screencenter screenCenter�! 
0 new_x1  �  
0 new_x2  �  �  �  �  �  �  �  �  �  �  �  �  �  �  �   �$��%&�
� .aevtoappnull  �   � ****$ k    6''  ((  6))  _**  f++  q��  �  �  %  & ( .��
�	����� @� B P��� ���������������������������� � �����������������
� 
desk
�
 
cwin
�	 
pbnd� 0 b  
� 
cobj� 0 displaywidth displayWidth� � 0 displayheight displayHeight
� .sysoexecTEXT���     TEXT
� 
nmbr� �  0 docksize dockSize�� �� 0 menubarsize menubarSize
�� appfegfp
�� 
rtyp
�� 
utxt
�� .earsffdralis        afdr�� 0 curapp curApp
�� 
capp�� 
0 cur_x1  �� 
0 cur_y1  �� 
0 cur_x2  �� 
0 cur_y2  �� 
0 new_y1  �� 
0 new_y2  
�� .coredoexnull���     obj �� ,�� 0 windowcenter windowCenter�� 0 screencenter screenCenter�� 
0 new_x1  �� 
0 new_x2  ��  ��  �7� *�,�,�,E�O��m/E�O���/E�UO�j 
�  �j 
�&�E�OPY jE�Oa E` Oa a a l E` O*a _ / � �*�k/ �*�,EE[�k/E` Z[�l/E` Z[�m/E` Z[��/E` ZO_ E` O�E` O_ a  #� a j   _ a !E` Y hUY hO_ _ l!E` "O���l!E` #O_ "_ # �E` $O���l!E` %Y ���l!E` $O�E` %O_ $_ _ %_ �v*�,FUW X & 'hU ��,�� ,  ����������  ��  ������J�I��H  �G   �-- l m a c O S : S y s t e m : A p p l i c a t i o n s : U t i l i t i e s : S c r i p t   E d i t o r . a p p :�F��E ,�D�C��B �A�! @�     " @�      �@  # @�      �?  �>  �=  �<  �;  �:  �9  �8  �7  �6  �5  �4  �3  �2  �1  ascr  ��ޭ
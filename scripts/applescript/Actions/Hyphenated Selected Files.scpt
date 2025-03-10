FasdUAS 1.101.10   ��   ��    k             l     ��  ��    � � This script changes spaces to hyphens, transforms camelCase and snake_case to hyphenated format, and converts filenames to lowercase for selected files in Finder     � 	 	D   T h i s   s c r i p t   c h a n g e s   s p a c e s   t o   h y p h e n s ,   t r a n s f o r m s   c a m e l C a s e   a n d   s n a k e _ c a s e   t o   h y p h e n a t e d   f o r m a t ,   a n d   c o n v e r t s   f i l e n a m e s   t o   l o w e r c a s e   f o r   s e l e c t e d   f i l e s   i n   F i n d e r   
  
 l     ��������  ��  ��        l     ��  ��    ' ! Get the selected files in Finder     �   B   G e t   t h e   s e l e c t e d   f i l e s   i n   F i n d e r      l     ����  r         e        n         1    ��
�� 
sele  m       �                                                                                  MACS  alis    2  macOS                      �ǇBD ����
Finder.app                                                     �����Ǉ        ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    m a c O S  &System/Library/CoreServices/Finder.app  / ��    o      ���� 0 selectedfiles selectedFiles��  ��        l     ��������  ��  ��        l     ��  ��    &   Loop through the selected files     �     @   L o o p   t h r o u g h   t h e   s e l e c t e d   f i l e s   ! " ! l   F #���� # X    F $�� % $ O    A & ' & k    @ ( (  ) * ) l   �� + ,��   + ' ! Get the current name of the file    , � - - B   G e t   t h e   c u r r e n t   n a m e   o f   t h e   f i l e *  . / . r      0 1 0 n     2 3 2 1    ��
�� 
pnam 3 o    ���� 0 afile aFile 1 o      ���� 0 filename fileName /  4 5 4 l  ! !��������  ��  ��   5  6 7 6 l  ! !�� 8 9��   8 � z Replace spaces with hyphens, transform camelCase to hyphenated format, snake_case to hyphenated, and convert to lowercase    9 � : : �   R e p l a c e   s p a c e s   w i t h   h y p h e n s ,   t r a n s f o r m   c a m e l C a s e   t o   h y p h e n a t e d   f o r m a t ,   s n a k e _ c a s e   t o   h y p h e n a t e d ,   a n d   c o n v e r t   t o   l o w e r c a s e 7  ; < ; r   ! 8 = > = I  ! 4�� ?��
�� .sysoexecTEXT���     TEXT ? b   ! 0 @ A @ b   ! . B C B b   ! , D E D b   ! * F G F b   ! ( H I H b   ! & J K J m   ! " L L � M M 
 e c h o   K n   " % N O N 1   # %��
�� 
strq O o   " #���� 0 filename fileName I m   & ' P P � Q Q    |   G l 	 ( ) R���� R m   ( ) S S � T T  t r   '   '   ' - '   |  ��  ��   E l 	 * + U���� U m   * + V V � W W L s e d   - E   ' s / ( [ a - z ] ) ( [ A - Z ] ) / ' \ 1 - \ L \ 2 / '   |  ��  ��   C l 	 , - X���� X m   , - Y Y � Z Z & s e d   - E   ' s / _ / - / g '   |  ��  ��   A l 	 . / [���� [ m   . / \ \ � ] ] 4 t r   ' [ : u p p e r : ] '   ' [ : l o w e r : ] '��  ��  ��   > o      ���� 0 newfilename newFileName <  ^ _ ^ l  9 9��������  ��  ��   _  ` a ` l  9 9�� b c��   b   Rename the file    c � d d     R e n a m e   t h e   f i l e a  e�� e r   9 @ f g f o   9 <���� 0 newfilename newFileName g n       h i h 1   = ?��
�� 
pnam i o   < =���� 0 afile aFile��   ' m     j j�                                                                                  MACS  alis    2  macOS                      �ǇBD ����
Finder.app                                                     �����Ǉ        ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    m a c O S  &System/Library/CoreServices/Finder.app  / ��  �� 0 afile aFile % o   
 ���� 0 selectedfiles selectedFiles��  ��   "  k�� k l     ��������  ��  ��  ��       �� l m��   l ��
�� .aevtoappnull  �   � **** m �� n���� o p��
�� .aevtoappnull  �   � **** n k     F q q   r r  !����  ��  ��   o ���� 0 afile aFile p  �������������� L�� P S V Y \����
�� 
sele�� 0 selectedfiles selectedFiles
�� 
kocl
�� 
cobj
�� .corecnte****       ****
�� 
pnam�� 0 filename fileName
�� 
strq
�� .sysoexecTEXT���     TEXT�� 0 newfilename newFileName�� G��,EE�O >�[��l kh  � '��,E�O���,%�%�%�%�%�%j E` O_ ��,FU[OY�� ascr  ��ޭ
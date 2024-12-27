CREATE OR REPLACE PROCEDURE VMSCMS.SP_BANK_AGGR_LIMITS
(
p_instcode		NUMBER		,
p_posonlinelimit	NUMBER		,
p_posofflinelimit	NUMBER		,
p_atmonlinelimit	NUMBER		,
p_atmofflinelimit	NUMBER		,
p_online_aggr_limit	OUT NUMBER	,
p_offline_aggr_limit	OUT NUMBER	,
p_errmsg		OUT VARCHAR2
)
IS



BEGIN

p_errmsg := 'OK'	;

	BEGIN

		IF p_instcode	= 3	THEN

			p_online_aggr_limit :=	GREATEST (p_posonlinelimit, p_atmonlinelimit);

			p_offline_aggr_limit :=	GREATEST (p_posofflinelimit, p_atmofflinelimit);

		ELSE

			p_online_aggr_limit :=   p_posonlinelimit	 + p_atmonlinelimit	;

			p_offline_aggr_limit :=   p_posofflinelimit + p_atmofflinelimit	;

		END IF;


	EXCEPTION

		WHEN no_data_found THEN

			p_errmsg := 'LOCATION CODE NOT FOUND'  ;

			RETURN ;

		WHEN others THEN

			p_errmsg := 'ERROR WHILE GETTTING LOCATION CODE ' ;

			RETURN ;


	END;



END;
/


show error